import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import DiscourseEmbed from '@/components/DiscourseEmbed';

describe('DiscourseEmbed', () => {
  it('should render without crashing', () => {
    render(<DiscourseEmbed discourseUrl="https://forum.robbedbyapplecare.com/" />);
    expect(screen.getByRole('region')).toBeInTheDocument();
  });
});