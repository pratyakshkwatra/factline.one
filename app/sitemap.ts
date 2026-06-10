import { MetadataRoute } from 'next';
import { promises as fs } from 'fs';
import path from 'path';

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const sitemapData: MetadataRoute.Sitemap = [
    {
      url: 'https://factline.one',
      lastModified: new Date(),
      changeFrequency: 'daily',
      priority: 1,
    },
    {
      url: 'https://factline.one/archive',
      lastModified: new Date(),
      changeFrequency: 'daily',
      priority: 0.8,
    },
  ];

  try {
    const filePath = path.join(process.cwd(), 'public', 'data', 'index.json');
    const contents = await fs.readFile(filePath, 'utf8');
    const reports = JSON.parse(contents);

    reports.forEach((report: any) => {
      sitemapData.push({
        url: `https://factline.one/report/${report.slug}`,
        lastModified: new Date(report.published_at),
        changeFrequency: 'weekly',
        priority: 0.9,
      });
    });
  } catch (error) {
    // If index.json is not found or malformed, just return base URLs
  }

  return sitemapData;
}
