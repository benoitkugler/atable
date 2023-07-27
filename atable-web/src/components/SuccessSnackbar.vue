<template>
  <v-snackbar
    app
    :model-value="!!props.messages.length"
    @update:model-value="(s) => (!s ? emit('close') : null)"
    :timeout="-1"
    location="bottom right"
    color="success"
  >
    <v-row no-gutters>
      <v-col align-self="center" class="pr-2">
        <div v-for="(message, index) in messages" :key="index">
          <small> [{{ formatTime(message.time) }}] </small>
          {{ message.text }}
        </div>
      </v-col>
      <v-col cols="auto" align-self="center">
        <v-btn icon @click="emit('close')" class="mx-0" size="x-small">
          <v-icon color="black" size="small">mdi-close</v-icon>
        </v-btn>
      </v-col>
    </v-row>
  </v-snackbar>
</template>

<script lang="ts" setup>
const props = defineProps<{
  messages: { text: string; time: Date }[];
}>();

const emit = defineEmits<{
  (event: "close"): void;
}>();

const formatTime = (datetime: Date) =>
  datetime.toLocaleTimeString(undefined, {
    hour: "2-digit",
    minute: "2-digit",
  });
</script>
