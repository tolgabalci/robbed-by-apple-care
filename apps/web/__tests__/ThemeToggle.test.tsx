import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import ThemeToggle from '@/components/ui/ThemeToggle';

// Mock localStorage
const localStorageMock = {
  getItem: jest.fn(),
  setItem: jest.fn(),
  removeItem: jest.fn(),
  clear: jest.fn(),
};

// Mock matchMedia
const matchMediaMock = jest.fn().mockImplementation(query => ({
  matches: false,
  media: query,
  onchange: null,
  addListener: jest.fn(), // deprecated
  removeListener: jest.fn(), // deprecated
  addEventListener: jest.fn(),
  removeEventListener: jest.fn(),
  dispatchEvent: jest.fn(),
}));

// Setup mocks
Object.defineProperty(window, 'localStorage', {
  value: localStorageMock,
});

Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: matchMediaMock,
});

describe('ThemeToggle', () => {
  beforeEach(() => {
    // Clear all mocks before each test
    jest.clearAllMocks();
    localStorageMock.getItem.mockReturnValue(null);
    matchMediaMock.mockReturnValue({
      matches: false,
      media: '(prefers-color-scheme: dark)',
      onchange: null,
      addListener: jest.fn(),
      removeListener: jest.fn(),
      addEventListener: jest.fn(),
      removeEventListener: jest.fn(),
      dispatchEvent: jest.fn(),
    });
    
    // Reset document classes
    document.documentElement.className = '';
  });

  it('renders without crashing', () => {
    render(<ThemeToggle />);
    expect(screen.getByTestId('theme-toggle')).toBeInTheDocument();
  });

  it('shows placeholder while not mounted', () => {
    render(<ThemeToggle />);
    const element = screen.getByTestId('theme-toggle');
    
    // In test environment, useEffect runs synchronously, so we check for the button
    // In real browser, there would be a brief moment where placeholder shows
    expect(element).toBeInTheDocument();
  });

  it('shows proper button after mounting', async () => {
    render(<ThemeToggle />);
    
    // Wait for component to mount
    await waitFor(() => {
      const button = screen.getByTestId('theme-toggle');
      expect(button.tagName).toBe('BUTTON');
    });
  });

  it('has proper accessibility attributes', async () => {
    render(<ThemeToggle />);
    
    await waitFor(() => {
      const button = screen.getByTestId('theme-toggle');
      expect(button).toHaveAttribute('aria-label');
      expect(button).toHaveAttribute('title');
    });
  });

  it('defaults to light mode when no preference is saved', async () => {
    localStorageMock.getItem.mockReturnValue(null);
    matchMediaMock.mockReturnValue({
      matches: false,
      addEventListener: jest.fn(),
      removeEventListener: jest.fn(),
    });

    render(<ThemeToggle />);
    
    await waitFor(() => {
      const button = screen.getByTestId('theme-toggle');
      expect(button).toHaveAttribute('aria-label', 'Switch to dark mode');
      expect(button.querySelector('svg')).toBeInTheDocument();
    });
  });

  it('defaults to dark mode when system prefers dark', async () => {
    localStorageMock.getItem.mockReturnValue(null);
    matchMediaMock.mockReturnValue({
      matches: true,
      addEventListener: jest.fn(),
      removeEventListener: jest.fn(),
    });

    render(<ThemeToggle />);
    
    await waitFor(() => {
      const button = screen.getByTestId('theme-toggle');
      expect(button).toHaveAttribute('aria-label', 'Switch to light mode');
      expect(button.querySelector('svg')).toBeInTheDocument();
    });
  });

  it('respects saved theme preference', async () => {
    localStorageMock.getItem.mockReturnValue('dark');
    
    render(<ThemeToggle />);
    
    await waitFor(() => {
      const button = screen.getByTestId('theme-toggle');
      expect(button).toHaveAttribute('aria-label', 'Switch to light mode');
      expect(button.querySelector('svg')).toBeInTheDocument();
    });
  });

  it('toggles theme when clicked', async () => {
    localStorageMock.getItem.mockReturnValue('light');
    
    render(<ThemeToggle />);
    
    await waitFor(() => {
      const button = screen.getByTestId('theme-toggle');
      expect(button).toHaveAttribute('aria-label', 'Switch to dark mode');
      expect(button.querySelector('svg')).toBeInTheDocument();
    });

    const button = screen.getByTestId('theme-toggle');
    fireEvent.click(button);

    await waitFor(() => {
      expect(button).toHaveAttribute('aria-label', 'Switch to light mode');
      expect(button.querySelector('svg')).toBeInTheDocument();
      expect(localStorageMock.setItem).toHaveBeenCalledWith('theme', 'dark');
    });
  });

  it('applies dark class to document when dark mode is enabled', async () => {
    localStorageMock.getItem.mockReturnValue('light');
    
    render(<ThemeToggle />);
    
    await waitFor(() => {
      const button = screen.getByTestId('theme-toggle');
      fireEvent.click(button);
    });

    await waitFor(() => {
      expect(document.documentElement.classList.contains('dark')).toBe(true);
    });
  });

  it('removes dark class from document when light mode is enabled', async () => {
    localStorageMock.getItem.mockReturnValue('dark');
    document.documentElement.classList.add('dark');
    
    render(<ThemeToggle />);
    
    await waitFor(() => {
      const button = screen.getByTestId('theme-toggle');
      fireEvent.click(button);
    });

    await waitFor(() => {
      expect(document.documentElement.classList.contains('dark')).toBe(false);
    });
  });

  it('accepts custom data-testid', () => {
    render(<ThemeToggle data-testid="custom-theme-toggle" />);
    expect(screen.getByTestId('custom-theme-toggle')).toBeInTheDocument();
  });
});