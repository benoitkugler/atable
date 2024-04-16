<template>
  <v-container class="fill-height" fluid>
    <v-card title="Réglages" width="100%">
      <v-card-text v-if="settings != null">
        <v-row>
          <v-col>
            <v-text-field
              label="Email"
              density="compact"
              variant="outlined"
              v-model="settings.Mail"
            ></v-text-field>
          </v-col>
          <v-col>
            <v-text-field
              label="Mot de passe"
              density="compact"
              variant="outlined"
              v-model="settings.Password"
            ></v-text-field>
          </v-col>
          <v-col>
            <v-text-field
              label="Pseudo"
              density="compact"
              variant="outlined"
              v-model="settings.Pseudo"
            ></v-text-field>
          </v-col>
        </v-row>
      </v-card-text>
      <v-card-actions>
        <v-spacer></v-spacer>
        <v-btn color="success" :disabled="!isDirty" @click="update">
          Enregistrer
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-container>
</template>

<script setup lang="ts">
import { controller, copy } from "@/logic/controller";
import { User } from "@/logic/api_gen";
import { ref } from "vue";
import { onMounted } from "vue";
import { computed } from "vue";

const emit = defineEmits<{}>();

const initialValue = ref<User | null>(null);
const settings = ref<User | null>(null);

onMounted(fetch);

async function fetch() {
  const res = await controller.UserGetSettings();
  if (res === undefined) return;
  initialValue.value = copy(res);
  settings.value = res;
}

const isDirty = computed(
  () => JSON.stringify(settings.value) != JSON.stringify(initialValue.value)
);

async function update() {
  if (settings.value == null) return;
  const res = await controller.UserUpdateSettings(settings.value);
  if (res === undefined) return;
  initialValue.value = copy(settings.value);
  controller.showMessage("Réglages mis à jour avec succès.");
}
</script>

<style></style>
