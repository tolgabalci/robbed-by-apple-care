import { ReactNode, ButtonHTMLAttributes, AnchorHTMLAttributes } from 'react';

interface BaseButtonProps {
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  children: ReactNode;
  className?: string;
}

interface ButtonAsButton extends BaseButtonProps, Omit<ButtonHTMLAttributes<HTMLButtonElement>, 'children'> {
  as?: 'button';
}

interface ButtonAsLink extends BaseButtonProps, Omit<AnchorHTMLAttributes<HTMLAnchorElement>, 'children'> {
  as: 'a';
}

type ButtonProps = ButtonAsButton | ButtonAsLink;

export default function Button({ 
  variant = 'primary', 
  size = 'md', 
  children, 
  className = '',
  as = 'button',
  ...props 
}: ButtonProps) {
  const baseClasses = 'inline-flex items-center justify-center rounded-md font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-500 disabled:pointer-events-none disabled:opacity-50';
  
  const variantClasses = {
    primary: 'bg-primary-600 text-white hover:bg-primary-700 dark:bg-primary-500 dark:hover:bg-primary-600',
    secondary: 'bg-gray-200 text-gray-900 hover:bg-gray-300 dark:bg-gray-700 dark:text-gray-100 dark:hover:bg-gray-600',
    outline: 'border border-gray-300 bg-transparent text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-800',
    ghost: 'text-gray-700 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-800',
  };
  
  const sizeClasses = {
    sm: 'px-3 py-1.5 text-sm',
    md: 'px-4 py-2 text-sm',
    lg: 'px-6 py-3 text-base',
  };

  const classes = `${baseClasses} ${variantClasses[variant]} ${sizeClasses[size]} ${className}`;

  if (as === 'a') {
    return (
      <a className={classes} {...(props as AnchorHTMLAttributes<HTMLAnchorElement>)}>
        {children}
      </a>
    );
  }

  return (
    <button className={classes} {...(props as ButtonHTMLAttributes<HTMLButtonElement>)}>
      {children}
    </button>
  );
}