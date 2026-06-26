<template>
  <svg
    class="brand-mark"
    viewBox="0 0 84 72"
    xmlns="http://www.w3.org/2000/svg"
    aria-hidden="true"
    :style="{ width: sizeValue }"
  >
    <defs>
      <linearGradient :id="plateGradientId" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0%" stop-color="#0f766e" />
        <stop offset="100%" stop-color="#17929a" />
      </linearGradient>
      <linearGradient :id="foldGradientId" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0%" stop-color="#f59e0b" />
        <stop offset="100%" stop-color="#d97706" />
      </linearGradient>
      <linearGradient :id="pathGradientId" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0%" stop-color="#fff7ed" />
        <stop offset="100%" stop-color="#dff8f0" />
      </linearGradient>
    </defs>

    <path
      :fill="`url(#${plateGradientId})`"
      d="M10.6 49.4c-1.8-1.2-1.8-3.8 0-5l24.9-16.2c2.2-1.4 5 .2 5 2.8v29.8c0 2.6-2.8 4.2-5 2.8L10.6 49.4Z"
    />
    <path
      :fill="`url(#${foldGradientId})`"
      d="M31 19.8c0-1.4.8-2.7 2-3.4L51.9 6c2.6-1.4 5.8.4 5.8 3.3v20.4c0 1.5-.8 2.8-2.2 3.5L36.6 43.4c-2.5 1.3-5.6-.5-5.6-3.4V19.8Z"
    />
    <circle cx="64.5" cy="18" r="7.3" fill="#7ea889" />
    <path
      :stroke="`url(#${pathGradientId})`"
      d="M20.5 46.5c5.9-7.9 13.3-13.2 22.9-15.8 7.4-2 13.5-1.4 20.4-2.8"
      stroke-width="3.4"
      stroke-linecap="round"
      stroke-linejoin="round"
      opacity="0.94"
    />
    <circle cx="20.5" cy="46.5" r="3.5" fill="#fffdf8" />
    <circle cx="64" cy="27.8" r="3.2" fill="#fffdf8" />
  </svg>
</template>

<script>
export default {
  name: 'BrandMark',
  props: {
    size: {
      type: [Number, String],
      default: 40
    }
  },
  data() {
    return {
      uid: `brand-${Math.random().toString(36).slice(2, 10)}`
    }
  },
  computed: {
    sizeValue() {
      return typeof this.size === 'number' ? `${this.size}px` : this.size
    },
    plateGradientId() {
      return `${this.uid}-plate`
    },
    foldGradientId() {
      return `${this.uid}-fold`
    },
    pathGradientId() {
      return `${this.uid}-path`
    }
  }
}
</script>

<style scoped>
.brand-mark {
  display: block;
  height: auto;
}
</style>
