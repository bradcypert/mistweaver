import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'Mistweaver',
  description: 'A Phoenix-inspired web framework for Gleam',
  base: '/mistweaver/',

  themeConfig: {
    nav: [
      { text: 'Guide', link: '/guide/introduction' },
      { text: 'Reference', link: '/reference/router' },
      { text: 'GitHub', link: 'https://github.com/bradcypert/mistweaver' },
    ],

    sidebar: {
      '/guide/': [
        {
          text: 'Getting Started',
          items: [
            { text: 'Introduction', link: '/guide/introduction' },
            { text: 'Installation', link: '/guide/installation' },
            { text: 'Your First App', link: '/guide/first-app' },
          ],
        },
        {
          text: 'Core Concepts',
          items: [
            { text: 'Routing', link: '/guide/routing' },
            { text: 'Conn', link: '/guide/conn' },
            { text: 'Middleware', link: '/guide/middleware' },
            { text: 'Sessions & Auth', link: '/guide/sessions' },
            { text: 'LiveView', link: '/guide/liveview' },
          ],
        },
        {
          text: 'Features',
          items: [
            { text: 'Forms & Changesets', link: '/guide/changesets' },
            { text: 'File Uploads', link: '/guide/uploads' },
            { text: 'PubSub', link: '/guide/pubsub' },
            { text: 'Mailer', link: '/guide/mailer' },
            { text: 'Config', link: '/guide/config' },
            { text: 'Telemetry', link: '/guide/telemetry' },
            { text: 'Testing', link: '/guide/testing' },
          ],
        },
      ],
      '/reference/': [
        {
          text: 'API Reference',
          items: [
            { text: 'router', link: '/reference/router' },
            { text: 'conn', link: '/reference/conn' },
            { text: 'middleware', link: '/reference/middleware' },
            { text: 'auth', link: '/reference/auth' },
            { text: 'session', link: '/reference/session' },
            { text: 'live', link: '/reference/live' },
            { text: 'changeset', link: '/reference/changeset' },
            { text: 'multipart', link: '/reference/multipart' },
            { text: 'pubsub', link: '/reference/pubsub' },
            { text: 'mailer', link: '/reference/mailer' },
            { text: 'config', link: '/reference/config' },
            { text: 'telemetry', link: '/reference/telemetry' },
            { text: 'rescue', link: '/reference/rescue' },
            { text: 'test_conn', link: '/reference/test_conn' },
          ],
        },
      ],
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/bradcypert/mistweaver' },
    ],

    footer: {
      message: 'Released under the Apache 2.0 License.',
    },
  },
})
