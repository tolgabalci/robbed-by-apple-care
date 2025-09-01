import { ImageResponse } from 'next/og';

export const runtime = 'edge';

export const alt = 'Robbed by AppleCare - A Customer Service Nightmare';
export const size = {
  width: 1200,
  height: 630,
};
export const contentType = 'image/png';

export default async function Image() {
  // Static content for the OG image since we can't access fs in edge runtime
  const title = "Robbed by AppleCare: A Customer Service Nightmare";
  const subtitle = "How Apple's premium support service failed me when I needed it most";
  const author = "Anonymous Customer";
  const date = "January 15, 2024";

  return new ImageResponse(
    (
      <div
        style={{
          height: '100%',
          width: '100%',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          backgroundColor: '#1f2937',
          backgroundImage: 'linear-gradient(45deg, #1f2937 0%, #374151 100%)',
        }}
      >
        <div
          style={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            padding: '40px',
            textAlign: 'center',
            maxWidth: '1000px',
          }}
        >
          <h1
            style={{
              fontSize: '56px',
              fontWeight: 'bold',
              color: '#ffffff',
              lineHeight: '1.1',
              marginBottom: '20px',
              textAlign: 'center',
            }}
          >
            {title}
          </h1>
          <p
            style={{
              fontSize: '24px',
              color: '#d1d5db',
              lineHeight: '1.4',
              marginBottom: '30px',
              textAlign: 'center',
            }}
          >
            {subtitle}
          </p>
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '20px',
              fontSize: '18px',
              color: '#9ca3af',
            }}
          >
            <span>By {author}</span>
            <span>•</span>
            <span>{date}</span>
          </div>
        </div>
        <div
          style={{
            position: 'absolute',
            bottom: '40px',
            right: '40px',
            fontSize: '18px',
            color: '#6b7280',
          }}
        >
          robbedbyapplecare.com
        </div>
      </div>
    ),
    {
      ...size,
    }
  );
}