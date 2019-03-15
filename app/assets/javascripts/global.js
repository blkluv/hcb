// BK is our global namespace for utilities
const BK = {
  blocked: false
}
// BK.s('some_behavior') is a shortcut for selecting elements by data-behavior
BK.s = (selector, filter = '') =>
  $(`[data-behavior~=${selector}]`).filter(
    filter.length > 0 ? filter : () => true
  )
BK.thereIsNot = (selector, filter) => BK.s(selector, filter).is(':empty')
BK.thereIs = (selector, filter) => !BK.thereIsNot(selector, filter)

BK.deselect = (selector, filter = '[aria-selected=true]') =>
  BK.s(selector, filter).attr('aria-selected', false)
BK.select = (selector, filter) =>
  BK.s(selector, filter).attr('aria-selected', true)

// Annoy users without FullStory
$(document).ready(() => {
  setTimeout(() => {
    if (typeof FS === 'undefined') {
      BK.blocked = true
    } else {
      fetch('https://rs.fullstory.com/rec/page', { method: 'POST' })
        .then(res => {
          if (!res.ok) {
            BK.blocked = true
          }
        })
        .catch(() => {
          BK.blocked = true
        })
    }
  }, 3000)
  setTimeout(() => {
    if (BK.blocked) {
      alert(
        'Hack Club Bank is still in development. To continue improving the product, it’s crucial for us to debug any issues that arise, but your adblocker is currently blocking our bug reporting + analytics. Please unblock before continuing to use the app.'
      )
    }
  }, 3250)
})

// https://css-tricks.com/snippets/jquery/get-query-params-object/
BK.getQueryParams = () => {
  const result = {}
  const kvPairs = window.location.search.substr(1).split('&')
  for (let i = 0; i < kvPairs.length; i++) {
    const [k, v] = kvPairs[i].split('=')
    if (k) {
      result[k] = decodeURIComponent(v)
    }
  }
  return result
}
