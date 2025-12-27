import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: 'https://fluentasserts.szabobogdan.com',
  integrations: [
    sitemap(),
    starlight({
      title: 'fluent-asserts',
      favicon: '/favicon.svg',
      description: 'Fluent assertion framework for the D programming language. Write readable, expressive tests with a fluent API.',
      head: [
        // Open Graph / Social sharing
        {
          tag: 'meta',
          attrs: { property: 'og:type', content: 'website' },
        },
        {
          tag: 'meta',
          attrs: { property: 'og:site_name', content: 'fluent-asserts' },
        },
        {
          tag: 'meta',
          attrs: { property: 'og:image', content: 'https://fluentasserts.szabobogdan.com/og-image.png' },
        },
        {
          tag: 'meta',
          attrs: { property: 'og:locale', content: 'en_US' },
        },
        // Twitter Card
        {
          tag: 'meta',
          attrs: { name: 'twitter:card', content: 'summary_large_image' },
        },
        {
          tag: 'meta',
          attrs: { name: 'twitter:image', content: 'https://fluentasserts.szabobogdan.com/og-image.png' },
        },
        // Additional SEO
        {
          tag: 'meta',
          attrs: { name: 'keywords', content: 'D language, dlang, unit testing, assertions, fluent API, testing framework, expect, BDD' },
        },
        {
          tag: 'meta',
          attrs: { name: 'author', content: 'Bogdan Szabo' },
        },
        {
          tag: 'link',
          attrs: { rel: 'canonical', href: 'https://fluentasserts.szabobogdan.com' },
        },
        // Structured Data (JSON-LD)
        {
          tag: 'script',
          attrs: { type: 'application/ld+json' },
          content: JSON.stringify({
            '@context': 'https://schema.org',
            '@type': 'SoftwareSourceCode',
            name: 'fluent-asserts',
            description: 'Fluent assertion framework for the D programming language. Write readable, expressive tests with a fluent API.',
            url: 'https://fluentasserts.szabobogdan.com',
            codeRepository: 'https://github.com/gedaiu/fluent-asserts',
            programmingLanguage: {
              '@type': 'ComputerLanguage',
              name: 'D',
              alternateName: 'dlang',
            },
            author: {
              '@type': 'Person',
              name: 'Bogdan Szabo',
            },
            license: 'https://opensource.org/licenses/BSL-1.0',
            applicationCategory: 'DeveloperApplication',
            operatingSystem: 'Cross-platform',
          }),
        },
        // Matomo Analytics
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
