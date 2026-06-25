<template>
  <div class="date-separator">
    <span class="label">{{ label }}</span>
  </div>
</template>

<script>
export default {
  name: 'DateSeparator',
  props: {
    label: { type: String, required: true }
  }
}
</script>

<style scoped>
.date-separator {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  margin: 16px 0;
  padding: 0 8px;
}
.date-separator::before,
.date-separator::after {
  content: '';
  flex: 1;
  height: 1px;
  background: linear-gradient(90deg, transparent, var(--border-color), transparent);
}
.label {
  background: linear-gradient(135deg, #faf8f5, #f5f0ea);
  color: var(--color-text-muted);
  border-radius: 9999px;
  padding: 5px 14px;
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.3px;
  text-transform: uppercase;
  border: 1px solid rgba(231,224,215,0.6);
  box-shadow: 0 1px 4px rgba(0,0,0,0.04);
  white-space: nowrap;
}
</style>