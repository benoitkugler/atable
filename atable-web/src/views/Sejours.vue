<template>
  <v-container class="fill-height">
    <v-dialog
      :model-value="sejourToEdit != null"
      @update:model-value="sejourToEdit = null"
      max-width="400px"
    >
      <v-card v-if="sejourToEdit != null" title="Modifier le séjour">
        <v-card-text>
          <v-form>
            <v-row>
              <v-col>
                <v-text-field
                  label="Nom"
                  variant="outlined"
                  density="comfortable"
                  v-model="sejourToEdit.Sejour.Name"
                ></v-text-field>
              </v-col>
            </v-row>
            <v-row>
              <v-col>
                <date-field
                  v-model="sejourToEdit.Sejour.Start"
                  label="Date de début"
                ></date-field>
              </v-col>
            </v-row>
          </v-form>
        </v-card-text>
        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn color="success" @click="updateSejour">Enregistrer</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-dialog
      :model-value="sejourToDelete != null"
      @update:model-value="sejourToDelete = null"
      max-width="600px"
    >
      <v-card v-if="sejourToDelete != null" title="Confirmer la suppression">
        <v-card-text>
          Confirmez-vous la suppression du séjour
          {{ sejourToDelete.Sejour.Name }} ? <br />
          Cette opération est irréversible.
        </v-card-text>
        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn color="red" @click="deleteSejour">Supprimer</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-responsive class="align-center text-center fill-height">
      <v-card color="grey-lighten-4">
        <v-row justify="space-between" class="pa-2">
          <v-col cols="auto">
            <v-card-title>Séjours</v-card-title>
          </v-col>
          <v-col cols="auto" align-self="center">
            <v-btn class="mr-2" @click="createSejour">
              <template v-slot:prepend="">
                <v-icon color="green">mdi-plus</v-icon>
              </template>
              Ajouter un séjour
            </v-btn>
          </v-col>
        </v-row>
        <v-card-text>
          <v-card class="mt-2" elevation="0">
            <v-row justify="center" class="mx-1 mt-2">
              <v-col align-self="center" cols="6">
                <v-select
                  :items="selectItems"
                  v-model="activeSejour"
                  @update:model-value="notifyActiveSejour"
                  class="my-2"
                  variant="outlined"
                  label="Séjour actif"
                  hide-details
                  no-data-text="Veuillez ajouter un nouveau séjour..."
                ></v-select>
              </v-col>
              <v-col cols="auto" align-self="center">
                <v-btn
                  flat
                  icon
                  class="mx-1"
                  size="small"
                  @click="sejourToEdit = activeSejour"
                >
                  <v-icon>mdi-pencil</v-icon>
                </v-btn>
                <v-btn
                  flat
                  icon
                  class="mx-1"
                  size="small"
                  @click="sejourToDelete = activeSejour"
                >
                  <v-icon color="red">mdi-delete</v-icon>
                </v-btn>
              </v-col>
            </v-row>
            <v-card-text>
              <group-list
                v-if="activeSejour != null"
                :sejour="activeSejour"
                @update="updateGroup"
                @delete="deleteGroup"
                @create="createGroup"
                ref="groupList"
              ></group-list>
            </v-card-text>
          </v-card>
        </v-card-text>
      </v-card>
    </v-responsive>
  </v-container>
</template>

<script lang="ts" setup>
import DateField from "@/components/DateField.vue";
import GroupList from "@/components/sejours/GroupList.vue";
import { Group, SejourExt } from "@/logic/api_gen";
import { controller } from "@/logic/controller";
import { onActivated } from "vue";
import { computed } from "vue";
import { onMounted } from "vue";
import { ref } from "vue";

onMounted(fetchSejours);
onActivated(fetchSejours);

const sejours = ref<SejourExt[]>([]);
const selectItems = computed(() =>
  sejours.value.map((s) => ({ title: s.Sejour.Name, value: s }))
);

const activeSejour = ref<SejourExt | null>(controller.activeSejour);

function notifyActiveSejour() {
  controller.activeSejour = activeSejour.value;
}

async function fetchSejours() {
  const res = await controller.SejoursGet();
  if (res === undefined) return;
  sejours.value = res || [];

  ensureSelected();
}

async function createSejour() {
  const res = await controller.SejoursCreate();
  if (res === undefined) return;

  controller.showMessage!("Séjour ajouté avec succès.");
  sejours.value.push(res);

  activeSejour.value = res;
  notifyActiveSejour();
  sejourToEdit.value = res;
}

function ensureSelected() {
  if (activeSejour.value != null) return;

  if (controller.activeSejour == null && sejours.value.length != 0) {
    controller.activeSejour = sejours.value[0];
  }

  activeSejour.value = controller.activeSejour;
}

const sejourToDelete = ref<SejourExt | null>(null);
async function deleteSejour() {
  const toDelete = sejourToDelete.value;
  if (toDelete == null) return;
  const res = await controller.SejoursDelete({ id: toDelete.Sejour.Id });
  if (res == undefined) return;

  controller.showMessage!("Séjour supprimé avec succès.");
  sejours.value = sejours.value.filter(
    (s) => s.Sejour.Id != toDelete.Sejour.Id
  );
  activeSejour.value = null;
  controller.activeSejour = null;
  sejourToDelete.value = null;

  ensureSelected();
}

const sejourToEdit = ref<SejourExt | null>(null);
async function updateSejour() {
  const toEdit = sejourToEdit.value;
  if (toEdit == null) return;
  const res = await controller.SejoursUpdate(toEdit.Sejour);
  if (res == undefined) return;

  controller.showMessage!("Séjour modifié avec succès.");
  const index = sejours.value.findIndex(
    (sej) => sej.Sejour.Id == toEdit.Sejour.Id
  );
  sejours.value[index] = toEdit;

  activeSejour.value = toEdit;
  sejourToEdit.value = null;
}

const groupList = ref<InstanceType<typeof GroupList> | null>(null);
async function createGroup() {
  const sej = activeSejour.value;
  if (sej == null) return;
  const res = await controller.SejoursCreateGroupe({
    "id-sejour": sej.Sejour.Id,
  });
  if (res == undefined) return;
  controller.showMessage!("Groupe ajouté avec succès.");

  sej.Groups = (sej.Groups || []).concat(res);
  notifyActiveSejour();
  groupList.value?.startEdit(res);
}

async function updateGroup(group: Group) {
  const res = await controller.SejoursUpdateGroupe(group);
  if (res == undefined) return;
  controller.showMessage!("Groupe modifié avec succès.");

  const l = activeSejour.value?.Groups || [];
  const index = l.findIndex((g) => g.Id == group.Id);
  l[index] = group;
  notifyActiveSejour();
}

async function deleteGroup(group: Group) {
  const res = await controller.SejoursDeleteGroupe({ "id-group": group.Id });
  if (res == undefined) return;
  controller.showMessage!("Groupe supprimé avec succès.");

  const l = activeSejour.value?.Groups || [];
  activeSejour.value!.Groups = l.filter((g) => g.Id != group.Id);
  notifyActiveSejour();
}
</script>
