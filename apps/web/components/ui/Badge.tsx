import { ReactNode } from 'react';

interface BadgeProps {
  variant?: 'primary' | 'secondary' | 'success' | 'warning' | 'error';
  size?: 'sm' | 'md';
  children: ReactNode;
  className?: string;
}

export default function Badge({ 
  variant = 'primary', 
  size = 'md', 
  children, 
  className = '' 
}: BadgeProps) {
  const baseClasses = 'inline-flex items-center rounded-full font-medium';
  
  const variantClasses = {
    primary: 'bg-primary-100 text-primary-800 dark:bg-primary-900 dark:text-primary-200',
    secondary: 'bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-200',
    success: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200',
    warning: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200',
    error: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200',
  };
  
  const sizeClasses = {
    sm: 'px-2 py-0.5 text-xs',
    md: 'px-2.5 py-0.5 text-xs',
  };

  return (
    <span className={`${baseClasses} ${variantClasses[variant]} ${sizeClasses[size]} ${className}`}>
      {children}
    </span>
  );
}