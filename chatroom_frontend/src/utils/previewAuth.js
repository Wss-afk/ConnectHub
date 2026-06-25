const PREVIEW_TOKEN_PREFIX = 'preview-token:'

const PREVIEW_USERS = {
  user: {
    id: 1,
    username: 'Preview User',
    role: 'USER',
    avatarUrl: ''
  },
  admin: {
    id: 999,
    username: 'Preview Admin',
    role: 'SUPER_ADMIN',
    avatarUrl: ''
  }
}

function isDevelopment() {
  return process.env.NODE_ENV === 'development'
}

function clearPreviewParam(url) {
  url.searchParams.delete('preview')
  const search = url.searchParams.toString()
  const nextUrl = `${url.pathname}${search ? `?${search}` : ''}${url.hash}`
  window.history.replaceState({}, '', nextUrl)
}

export async function applyPreviewAuthFromUrl(store) {
  if (!isDevelopment() || typeof window === 'undefined') {
    return null
  }

  const url = new URL(window.location.href)
  const previewMode = url.searchParams.get('preview')
  if (!previewMode) {
    return null
  }

  if (previewMode === 'off') {
    const currentToken = store?.state?.auth?.token || localStorage.getItem('auth_token') || ''
    if (String(currentToken).startsWith(PREVIEW_TOKEN_PREFIX)) {
      await store.dispatch('auth/logout')
    }
    clearPreviewParam(url)
    return 'off'
  }

  const previewUser = PREVIEW_USERS[previewMode]
  if (!previewUser) {
    clearPreviewParam(url)
    return null
  }

  await store.dispatch('auth/login', {
    user: previewUser,
    token: `${PREVIEW_TOKEN_PREFIX}${previewMode}`
  })
  clearPreviewParam(url)
  return previewMode
}
