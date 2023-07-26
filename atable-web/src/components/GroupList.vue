<template>
  <v-card>
    <v-row justify="space-between">
      <v-col cols="auto" align-self="center">
        <v-card-title> Groupes </v-card-title>
      </v-col>
      <v-col cols="auto" align-self="center">
        <v-btn class="mr-2" density="comfortable">
          <template v-slot:prepend>
            <v-icon color="green">mdi-plus</v-icon>
          </template>
          Ajouter un groupe</v-btn
        >
      </v-col>
    </v-row>
    <v-card-text>
      <i></i>
    </v-card-text>
  </v-card>
</template>

<script lang="ts" setup>
//

const props = defineProps<{
  sejour: SejourExt;
}>();
</script>
