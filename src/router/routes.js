const routes = [
  {
    path: '/',
    component: () => import('pages/LandingPage.vue'),
  },
  {
    path: '/practice',
    name: 'practice-index',
    component: import('pages/practice/PracticeIndex.vue'),
  },
  {
    path: '/practice/:id',
    name: 'practice-detail',
    component: import('pages/practice/PracticeDetail.vue'),
    props: true,
  },

  // Always leave this as last one,
  // but you can also remove it
  {
    path: '/:catchAll(.*)*',
    component: () => import('pages/ErrorNotFound.vue'),
  },
]

export default routes
/*
const routes = [
  {
    path: '/',
    component: () => import('layouts/MainLayout.vue'),
    children: [{ path: '', component: () => import('src/pages/LandingPage.vue') }],
  },

*/
