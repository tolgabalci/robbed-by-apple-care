import { MDXComponents } from 'mdx/types';
import { ReactNode } from 'react';

// Custom callout component for info boxes
function Callout({ 
  children, 
  type = 'info' 
}: { 
  children: ReactNode; 
  type?: 'info' | 'warning' | 'error' | 'success';
}) {
  const typeClasses = {
    info: 'callout-info',
    warning: 'callout-warning',
    error: 'callout-error',
    success: 'callout callout-info', // Using info style for success
  };

  return (
    <div className={typeClasses[type]}>
      {children}
    </div>
  );
}

// Custom heading component with anchor links
function Heading({ 
  level, 
  children, 
  ...props 
}: { 
  level: 1 | 2 | 3 | 4 | 5 | 6; 
  children?: ReactNode;
  id?: string;
  [key: string]: any;
}) {
  const Tag = `h${level}` as keyof JSX.IntrinsicElements;
  const id = props.id || (typeof children === 'string' 
    ? children.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '')
    : undefined
  );

  const headingClasses = {
    1: 'text-4xl font-bold mt-8 mb-4 text-gray-900 dark:text-gray-100',
    2: 'text-3xl font-semibold mt-8 mb-4 text-gray-900 dark:text-gray-100',
    3: 'text-2xl font-semibold mt-6 mb-3 text-gray-900 dark:text-gray-100',
    4: 'text-xl font-semibold mt-6 mb-3 text-gray-900 dark:text-gray-100',
    5: 'text-lg font-semibold mt-4 mb-2 text-gray-900 dark:text-gray-100',
    6: 'text-base font-semibold mt-4 mb-2 text-gray-900 dark:text-gray-100',
  };

  return (
    <Tag 
      id={id} 
      className={`${headingClasses[level]} scroll-mt-20 group`}
      {...props}
    >
      {id && (
        <a 
          href={`#${id}`} 
          className="opacity-0 group-hover:opacity-100 transition-opacity duration-200 text-blue-500 hover:text-blue-700 mr-2"
          aria-label={`Link to ${children}`}
        >
          #
        </a>
      )}
      {children}
    </Tag>
  );
}

// Enhanced paragraph component
function Paragraph({ children, ...props }: { children?: ReactNode; [key: string]: any }) {
  return (
    <p className="mb-4 text-gray-700 dark:text-gray-300 leading-relaxed" {...props}>
      {children}
    </p>
  );
}

// Enhanced list components
function UnorderedList({ children, ...props }: { children?: ReactNode; [key: string]: any }) {
  return (
    <ul className="mb-4 ml-6 space-y-2 list-disc text-gray-700 dark:text-gray-300" {...props}>
      {children}
    </ul>
  );
}

function OrderedList({ children, ...props }: { children?: ReactNode; [key: string]: any }) {
  return (
    <ol className="mb-4 ml-6 space-y-2 list-decimal text-gray-700 dark:text-gray-300" {...props}>
      {children}
    </ol>
  );
}

function ListItem({ children, ...props }: { children?: ReactNode; [key: string]: any }) {
  return (
    <li className="leading-relaxed" {...props}>
      {children}
    </li>
  );
}

// Enhanced blockquote
function Blockquote({ children, ...props }: { children?: ReactNode; [key: string]: any }) {
  return (
    <blockquote 
      className="border-l-4 border-gray-300 dark:border-gray-600 pl-4 py-2 my-6 italic text-gray-600 dark:text-gray-400 bg-gray-50 dark:bg-gray-800 rounded-r-lg" 
      {...props}
    >
      {children}
    </blockquote>
  );
}

// Code components
function InlineCode({ children, ...props }: { children?: ReactNode; [key: string]: any }) {
  return (
    <code 
      className="bg-gray-100 dark:bg-gray-800 text-gray-800 dark:text-gray-200 px-1.5 py-0.5 rounded text-sm font-mono" 
      {...props}
    >
      {children}
    </code>
  );
}

function CodeBlock({ children, ...props }: { children?: ReactNode; [key: string]: any }) {
  return (
    <pre className="bg-gray-900 dark:bg-gray-950 text-gray-100 p-4 rounded-lg overflow-x-auto my-6" {...props}>
      <code className="font-mono text-sm">{children}</code>
    </pre>
  );
}

// Links
function Link({ href, children, ...props }: { href?: string; children?: ReactNode; [key: string]: any }) {
  const isExternal = href?.startsWith('http');
  
  return (
    <a
      href={href}
      className="text-blue-600 hover:text-blue-800 underline transition-colors duration-200"
      target={isExternal ? '_blank' : undefined}
      rel={isExternal ? 'noopener noreferrer' : undefined}
      {...props}
    >
      {children}
    </a>
  );
}

// Horizontal rule
function HorizontalRule(props: any) {
  return <hr className="my-8 border-gray-300" {...props} />;
}

// Strong and emphasis
function Strong({ children, ...props }: { children?: ReactNode; [key: string]: any }) {
  return <strong className="font-semibold text-gray-900 dark:text-gray-100" {...props}>{children}</strong>;
}

function Emphasis({ children, ...props }: { children?: ReactNode; [key: string]: any }) {
  return <em className="italic" {...props}>{children}</em>;
}

// Export MDX components
export const mdxComponents: MDXComponents = {
  // Headings
  h1: (props) => <Heading level={1} {...props} />,
  h2: (props) => <Heading level={2} {...props} />,
  h3: (props) => <Heading level={3} {...props} />,
  h4: (props) => <Heading level={4} {...props} />,
  h5: (props) => <Heading level={5} {...props} />,
  h6: (props) => <Heading level={6} {...props} />,
  
  // Text elements
  p: Paragraph,
  strong: Strong,
  em: Emphasis,
  
  // Lists
  ul: UnorderedList,
  ol: OrderedList,
  li: ListItem,
  
  // Other elements
  blockquote: Blockquote,
  a: Link,
  hr: HorizontalRule,
  
  // Code
  code: InlineCode,
  pre: CodeBlock,
  
  // Custom components
  Callout,
};