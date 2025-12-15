import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
  site: 'https://fluentasserts.szabobogdan.com',
  integrations: [
    starlight({
      title: 'fluent-asserts',
      logo: {
        light: './src/assets/logo.svg',
        dark: './src/assets/logo-light.svg',
        replacesTitle: true,
      },
      social: {
        github: 'https://github.com/gedaiu/fluent-asserts',
      },
      sidebar: [
        {
          label: 'Guide',
          items: [
            { label: 'Introduction', link: '/guide/introduction/' },
            { label: 'Installation', link: '/guide/installation/' },
            { label: 'Assertion Styles', link: '/guide/assertion-styles/' },
            { label: 'Core Concepts', link: '/guide/core-concepts/' },
            { label: 'Memory Management', link: '/guide/memory-management/' },
            { label: 'Extending', link: '/guide/extending/' },
            { label: 'Philosophy', link: '/guide/philosophy/' },
            { label: 'Contributing', link: '/guide/contributing/' },
          ],
        },
        {
          label: 'API Reference',
          items: [
            { label: 'Overview', link: '/api/' },
            {
              label: 'Equality',
              autogenerate: { directory: 'api/equality' },
            },
            {
              label: 'Comparison',
              autogenerate: { directory: 'api/comparison' },
            },
            {
              label: 'Strings',
              autogenerate: { directory: 'api/strings' },
            },
            {
              label: 'Ranges & Arrays',
              autogenerate: { directory: 'api/ranges' },
            },
            {
              label: 'Callables & Exceptions',
              autogenerate: { directory: 'api/callable' },
            },
            {
              label: 'Types',
              autogenerate: { directory: 'api/types' },
            },
            {
              label: 'Other',
              autogenerate: { directory: 'api/other' },
            },
          ],
        },
      ],
      customCss: ['./src/styles/custom.css'],
    }),
  ],
});
