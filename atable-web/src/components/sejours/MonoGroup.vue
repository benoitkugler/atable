<template>
  <v-card elevation="0">
    <v-card-text>
      <v-row>
        <v-col align-self="center">
          <v-menu :close-on-content-click="false" v-model="showEdit">
            <template v-slot:activator="{ isActive, props: innerProps }">
              <v-chip
                color="secondary"
                size="x-large"
                v-on="{ isActive }"
                v-bind="innerProps"
              >
                {{ props.group.Size }}
              </v-chip>
            </template>
            <v-card title="Modifier la taille du séjour">
              <v-card-text>
                <v-text-field
                  variant="outlined"
                  density="compact"
                  label="Nombre de personnes"
                  type="number"
                  hide-details
                  v-model.number="innerSize"
                ></v-text-field>
              </v-card-text>
              <v-card-actions>
                <v-spacer></v-spacer>
                <v-btn color="success" @click="save">Enregistrer</v-btn>
              </v-card-actions>
            </v-card>
          </v-menu>
          personne{{ props.group.Size > 1 ? "s" : "" }}
        </v-col>
        <v-col cols="4">
          <v-alert color="blue-lighten-4">
            Votre séjour comporte plusieurs groupes ? <br />
            <v-btn class="mt-4 mb-2" flat @click="emit('create')"
              >Ajouter un groupe</v-btn
            >
          </v-alert>
        </v-col>
      </v-row>
    </v-card-text>
  </v-card>
</template>

<script lang="ts" setup>
import { Group } from "@/logic/api_gen";
import { copy } from "@/logic/controller";
import { watch } from "vue";
import { ref } from "vue";

const props = defineProps<{
  group: Group;
}>();

const emit = defineEmits<{
  (event: "update", g: Group): void;
  (event: "create"): void;
}>();

watch(props, () => (innerSize.value = props.group.Size));

const showEdit = ref(false);
const innerSize = ref(props.group.Size);

function save() {
  const v = copy(props.group);
  v.Size = innerSize.value;
  emit("update", v);
  showEdit.value = false;
}
</script>
