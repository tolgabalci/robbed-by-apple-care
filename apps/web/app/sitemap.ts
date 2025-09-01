import { MetadataRoute } from 'next';
import { getArticleMetadata } from '@/lib/mdx';

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const { frontmatter } = await getArticleMetadata();
  
  return [
    {
      url: 'https://www.robbedbyapplecare.com',
      lastModified: new Date(frontmatter.publishedAt),
      changeFrequency: 'monthly',
      priority: 1,
    },
    {
      url: 'https://forum.robbedbyapplecare.com',
      lastModified: new Date(),
      changeFrequency: 'daily',
      priority: 0.8,
    },
  ];
}