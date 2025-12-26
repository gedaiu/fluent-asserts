import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
  site: 'https://fluentasserts.szabobogdan.com',
  integrations: [
    starlight({
      title: 'fluent-asserts',
      favicon: '/favicon.svg',
      head: [
        {
          tag: 'script',
          content: `
            var _paq = window._paq = window._paq || [];
            _paq.push(['trackPageView']);
            _paq.push(['enableLinkTracking']);
            (function() {
              var u="https://analytics.giscollective.com/";
              _paq.push(['setTrackerUrl', u+'matomo.php']);
              _paq.push(['setSiteId', '12']);
              var d=document, g=d.createElement('script'), s=d.getElementsByTagName('script')[0];
              g.async=true; g.src=u+'matomo.js'; s.parentNode.insertBefore(g,s);
            })();
          `,
        },
      ],
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
            { label: 'Philosophy', link: '/guide/philosophy/' },
            { label: 'Installation', link: '/guide/installation/' },
            { label: 'Core Concepts', link: '/guide/core-concepts/' },
            { label: 'Assertion Styles', link: '/guide/assertion-styles/' },
            { label: 'Configuration', link: '/guide/configuration/' },
            { label: 'Context Data', link: '/guide/context-data/' },
            { label: 'Assertion Statistics', link: '/guide/statistics/' },
            { label: 'Memory Management', link: '/guide/memory-management/' },
            { label: 'Extending', link: '/guide/extending/' },
            { label: 'Contributing', link: '/guide/contributing/' },
            { label: 'Upgrading to v2', link: '/guide/upgrading-v2/' },
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
