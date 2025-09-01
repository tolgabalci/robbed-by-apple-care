import { ReactNode } from 'react';

interface CalloutProps {
  type?: 'info' | 'warning' | 'error' | 'success';
  title?: string;
  children: ReactNode;
  className?: string;
}

export default function Callout({ 
  type = 'info', 
  title, 
  children, 
  className = '' 
}: CalloutProps) {
  const baseClasses = 'rounded-lg border p-4 my-6';
  
  const typeClasses = {
    info: 'border-blue-200 bg-blue-50 dark:border-blue-800 dark:bg-blue-950',
    warning: 'border-yellow-200 bg-yellow-50 dark:border-yellow-800 dark:bg-yellow-950',
    error: 'border-red-200 bg-red-50 dark:border-red-800 dark:bg-red-950',
    success: 'border-green-200 bg-green-50 dark:border-green-800 dark:bg-green-950',
  };
  
  const titleClasses = {
    info: 'text-blue-800 dark:text-blue-200',
    warning: 'text-yellow-800 dark:text-yellow-200',
    error: 'text-red-800 dark:text-red-200',
    success: 'text-green-800 dark:text-green-200',
  };
  
  const contentClasses = {
    info: 'text-blue-700 dark:text-blue-300',
    warning: 'text-yellow-700 dark:text-yellow-300',
    error: 'text-red-700 dark:text-red-300',
    success: 'text-green-700 dark:text-green-300',
  };

  return (
    <div className={`${baseClasses} ${typeClasses[type]} ${className}`}>
      {title && (
        <h3 className={`font-semibold mb-2 ${titleClasses[type]}`}>
          {title}
        </h3>
      )}
      <div className={contentClasses[type]}>
        {children}
      </div>
    </div>
  );
}