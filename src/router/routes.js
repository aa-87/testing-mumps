const routes = [
  { path: '/', name: 'home', component: () => import('pages/LandingPage.vue') },
  {
    path: '/auth/signin',
    name: 'signin',
    component: () => import('pages/auth/SignIn.vue'),
    meta: { guestOnly: true },
  },
  {
    path: '/auth/signup',
    name: 'signup',
    component: () => import('pages/auth/SignUp.vue'),
    meta: { guestOnly: true },
  },
  {
    path: '/practice',
    name: 'practice-index',
    component: () => import('pages/practice/PracticeIndex.vue'),
    meta: { requiresAuth: true },
  },
  {
    path: '/practice/:id',
    name: 'practice-detail',
    component: () => import('pages/practice/PracticeDetail.vue'),
    props: true,
    meta: { requiresAuth: true },
  },
  {
    path: '/auth/verify',
    name: 'verify',
    component: () => import('pages/auth/VerifyEmail.vue'),
    meta: { guestAllowed: true },
  },
  {
    path: '/auth/forgot',
    name: 'forgot',
    component: () => import('pages/auth/ForgotPassword.vue'),
    meta: { guestAllowed: true },
  },
  {
    path: '/auth/reset',
    name: 'reset',
    component: () => import('pages/auth/ForgotPassword.vue'),
    meta: { guestAllowed: true },
  },
  {
    path: '/admin/users',
    name: 'admin-users',
    component: () => import('pages/admin/AdminUsers.vue'),
    meta: { requiresAdmin: true },
  },
  {
    path: '/admin/stats',
    name: 'admin-stats',
    component: () => import('pages/admin/AdminStats.vue'),
    meta: { requiresAdmin: true },
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
