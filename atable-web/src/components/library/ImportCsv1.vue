<template>
  <v-card-text>
    <v-form>
      <v-row>
        <v-col>
          <v-file-input
            variant="outlined"
            label="Fichier .CSV"
            :multiple="false"
            v-model="csvFiles"
            accept="text/csv"
          ></v-file-input>
        </v-col>
      </v-row>
    </v-form>
  </v-card-text>
  <v-card-actions>
    <v-spacer></v-spacer>
    <v-btn
      color="success"
      :disabled="!csvFiles.length"
      @click="emit('startImport', csvFiles[0])"
    >
      Démarrer l'import</v-btn
    >
  </v-card-actions>
</template>

<script setup lang="ts">
import { ref } from "vue";

// const props = defineProps<{}>();

const emit = defineEmits<{
  (e: "startImport", file: File): void;
}>();

const csvFiles = ref<File[]>([]);
</script>
