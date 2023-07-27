<template>
  <v-card class="ma-2">
    <v-row>
      <v-col cols="auto">
        <v-btn class="ma-1" flat @click="emit('back')">
          <template v-slot:prepend>
            <v-icon>mdi-arrow-left</v-icon>
          </template>
          Retour à la semaine</v-btn
        >
      </v-col>
    </v-row>
    <v-card-text>
      {{ props.offset }}
    </v-card-text>
  </v-card>
</template>

<script lang="ts" setup>
const props = defineProps<{
  offset: number;
}>();

const emit = defineEmits<{
  (event: "back"): void;
}>();
</script>
