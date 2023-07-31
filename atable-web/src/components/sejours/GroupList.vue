<template>
  <v-card elevation="0" title="Groupes">
    <v-dialog
      :model-value="toDelete != null"
      @update:model-value="toDelete = null"
      max-width="600px"
    >
      <v-card title="Confirmer la suppression" v-if="toDelete != null">
        <v-card-text>
          Confirmez-vous la suppression du groupe
          <i>{{ toDelete.Name || "Groupe par défaut" }} </i> ? <br />

          Cette opération est irréversible.
        </v-card-text>
        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn
            color="red"
            flat
            @click="
              emit('delete', toDelete);
              toDelete = null;
            "
            >Supprimer</v-btn
          >
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-dialog
      :model-value="toEdit != null"
      @update:model-value="toEdit = null"
      max-width="600px"
    >
      <v-card title="Modifier le groupe" v-if="toEdit != null">
        <v-card-text>
          <v-form>
            <v-row>
              <v-col>
                <v-text-field
                  variant="outlined"
                  density="compact"
                  label="Nom"
                  v-model="toEdit.Name"
                ></v-text-field>
              </v-col>
            </v-row>
            <v-row>
              <v-col>
                <v-text-field
                  variant="outlined"
                  density="compact"
                  label="Taille"
                  v-model.number="toEdit.Size"
                  type="number"
                  min="0"
                ></v-text-field>
              </v-col>
            </v-row>
            <v-row>
              <v-col>
                <ColorField v-model="toEdit.Color"></ColorField>
              </v-col>
            </v-row>
          </v-form>
        </v-card-text>
        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn
            flat
            color="success"
            @click="
              emit('update', toEdit);
              toEdit = null;
            "
            >Enregistrer</v-btn
          >
        </v-card-actions>
      </v-card>
    </v-dialog>

    <template v-slot:append>
      <v-btn class="mr-4" density="comfortable" @click="emit('create')">
        <template v-slot:prepend>
          <v-icon color="green">mdi-plus</v-icon>
        </template>
        Ajouter un groupe</v-btn
      >
    </template>
    <v-card-text>
      <v-alert v-if="!props.sejour.Groups?.length" class="mb-4">
        <i> Aucun groupe n'est défini. </i>
      </v-alert>
      <v-row>
        <v-col
          cols="6"
          v-for="(group, index) in props.sejour.Groups"
          :key="index"
        >
          <group-card
            :group="group"
            @update="toEdit = copy(group)"
            @delete="toDelete = copy(group)"
          ></group-card>
        </v-col>
      </v-row>
    </v-card-text>
  </v-card>
</template>

<script lang="ts" setup>
import { Group, SejourExt } from "@/logic/api_gen";
import GroupCard from "./GroupCard.vue";
import { copy } from "@/logic/controller";
import { ref } from "vue";
import ColorField from "../ColorField.vue";

//

const props = defineProps<{
  sejour: SejourExt;
}>();

const emit = defineEmits<{
  (event: "update", v: Group): void;
  (event: "delete", v: Group): void;
  (event: "create"): void;
}>();

const toEdit = ref<Group | null>(null);
const toDelete = ref<Group | null>(null);

defineExpose({ startEdit });

function startEdit(group: Group) {
  toEdit.value = group;
}
</script>
