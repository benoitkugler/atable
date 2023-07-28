<template>
  <v-card no-gutters>
    <v-card-text>
      <v-row justify="space-between">
        <v-col cols="5" align-self="center" style="text-align: left">
          <v-chip :color="props.group.Color" class="ma-2">
            {{ props.group.Name || "Groupe par défaut" }}
          </v-chip>
        </v-col>
        <v-col align-self="center">
          <v-chip color="secondary" size="large">
            {{ props.group.Size }}
          </v-chip>
          personne{{ props.group.Size > 1 ? "s" : "" }}
        </v-col>
        <v-col cols="auto" align-self="center">
          <v-btn class="mx-0" icon size="small" flat @click="emit('update')">
            <v-icon>mdi-pencil</v-icon>
          </v-btn>
          <v-btn class="mx-0" icon size="small" flat @click="emit('delete')">
            <v-icon color="red">mdi-delete</v-icon>
          </v-btn>
        </v-col>
      </v-row>
    </v-card-text>
  </v-card>
</template>

<script lang="ts" setup>
import { Group } from "@/logic/api_gen";

const props = defineProps<{
  group: Group;
}>();

const emit = defineEmits<{
  (event: "update"): void;
  (event: "delete"): void;
}>();
</script>
