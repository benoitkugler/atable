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

    <v-dialog v-model="showClientLinkDialog" max-width="800px">
      <v-card
        title="Exporter sur un smartphone"
        subtitle="Vous pouvez télécharger les repas d'un séjour sur l'application mobile À table !"
      >
        <v-card-text>
          <v-row>
            <v-col>
              <v-text-field
                label="Lien"
                readonly
                :model-value="rc.activeSejour!.ExportClientURL"
                hide-details
              >
              </v-text-field>
            </v-col>
            <v-col cols="auto" align-self="center">
              <v-btn icon="mdi-content-copy" @click="copyClientLink"> </v-btn>
            </v-col>
          </v-row>
          <v-row justify="center" no-gutters>
            <v-col cols="auto">
              <QRCodeVue3
                :value="rc.activeSejour!.ExportClientURL"
              ></QRCodeVue3>
            </v-col>
          </v-row>
        </v-card-text>
      </v-card>
    </v-dialog>

    <v-responsive class="align-center fill-height">
      <v-card color="grey-lighten-4" title="Séjours">
        <template v-slot:append>
          <v-menu>
            <template v-slot:activator="{ isActive, props }">
              <v-btn class="mr-2" v-on="{ isActive }" v-bind="props">
                <template v-slot:prepend="">
                  <v-icon color="green">mdi-plus</v-icon>
                </template>
                Ajouter un séjour
              </v-btn>
            </template>
            <v-list>
              <v-list-item @click="createSejour"
                >Créer un séjour vierge</v-list-item
              >
              <v-list-item
                :disabled="rc.activeSejour == null"
                @click="duplicateSejour"
                >Dupliquer le séjour
                <i>{{
                  rc.activeSejour == null ? "" : rc.activeSejour?.Label
                }}</i></v-list-item
              >
            </v-list>
          </v-menu>
        </template>
        <v-card-text>
          <v-card class="mt-2" elevation="0">
            <v-row class="mx-1 mt-2 px-4">
              <v-col align-self="center" cols="6">
                <v-select
                  :items="selectItems"
                  :model-value="rc.activeSejour?.Sejour.Id"
                  @update:model-value="updateActiveSejour"
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
                  :disabled="rc.activeSejour == null"
                  @click="sejourToEdit = copy(rc.activeSejour)"
                >
                  <v-icon>mdi-pencil</v-icon>
                </v-btn>
                <v-btn
                  flat
                  icon
                  class="mx-1"
                  size="small"
                  :disabled="rc.activeSejour == null"
                  @click="sejourToDelete = copy(rc.activeSejour)"
                >
                  <v-icon color="red">mdi-delete</v-icon>
                </v-btn>
              </v-col>
              <v-spacer></v-spacer>
              <v-col cols="auto" align-self="center">
                <v-btn
                  variant="outlined"
                  :disabled="rc.activeSejour == null"
                  @click="showClientLinkDialog = true"
                >
                  <template v-slot:append><v-icon>mdi-link</v-icon></template>
                  Copier sur un smartphone
                </v-btn>
              </v-col>
            </v-row>

            <v-card-text v-if="rc.activeSejour != null" class="text-center">
              <mono-group
                v-if="rc.activeSejour.Groups?.length == 1"
                :group="rc.activeSejour.Groups[0]"
                @update="updateGroup"
                @create="createGroup"
              ></mono-group>
              <group-list
                v-else
                :sejour="rc.activeSejour"
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
import MonoGroup from "@/components/sejours/MonoGroup.vue";
import QRCodeVue3 from "qrcode-vue3";
import { Group, SejourExt } from "@/logic/api_gen";
import { controller, copy } from "@/logic/controller";
import { onActivated } from "vue";
import { nextTick } from "vue";
import { reactive } from "vue";
import { computed } from "vue";
import { onMounted } from "vue";
import { ref } from "vue";

onMounted(fetchSejours);
onActivated(fetchSejours);

const sejours = ref<SejourExt[]>([]);
const selectItems = computed(() =>
  sejours.value.map((s) => ({ title: s.Label, value: s.Sejour.Id }))
);
function updateActiveSejour(id: number) {
  rc.activeSejour = sejours.value.find((s) => s.Sejour.Id == id)!;
}

const rc = reactive(controller);

async function fetchSejours() {
  const res = await controller.SejoursGet();
  if (res === undefined) return;
  sejours.value = res || [];

  ensureSelected();
}

async function createSejour() {
  const res = await controller.SejoursCreate();
  if (res === undefined) return;

  controller.showMessage("Séjour ajouté avec succès.");
  sejours.value.push(res);

  rc.activeSejour = res;
  sejourToEdit.value = res;
}

async function duplicateSejour() {
  if (rc.activeSejour == null) return;
  const res = await controller.SejoursDuplicate({
    "id-sejour": rc.activeSejour.Sejour.Id,
  });
  if (res === undefined) return;

  controller.showMessage("Séjour dupliqué avec succès.");
  sejours.value.push(res);

  rc.activeSejour = res;
  sejourToEdit.value = res;
}

function ensureSelected() {
  if (rc.activeSejour != null) return;

  if (sejours.value.length != 0) {
    rc.activeSejour = sejours.value[0];
  }
}

const sejourToDelete = ref<SejourExt | null>(null);
async function deleteSejour() {
  const toDelete = sejourToDelete.value;
  if (toDelete == null) return;
  const res = await controller.SejoursDelete({ id: toDelete.Sejour.Id });
  if (res == undefined) return;

  controller.showMessage("Séjour supprimé avec succès.");
  sejours.value = sejours.value.filter(
    (s) => s.Sejour.Id != toDelete.Sejour.Id
  );
  rc.activeSejour = null;
  sejourToDelete.value = null;

  ensureSelected();
}

const sejourToEdit = ref<SejourExt | null>(null);
async function updateSejour() {
  const toEdit = sejourToEdit.value;
  if (toEdit == null) return;
  const res = await controller.SejoursUpdate(toEdit.Sejour);
  if (res == undefined) return;

  controller.showMessage("Séjour modifié avec succès.");
  const index = sejours.value.findIndex(
    (sej) => sej.Sejour.Id == toEdit.Sejour.Id
  );
  sejours.value[index] = toEdit;

  rc.activeSejour = toEdit;
  sejourToEdit.value = null;
}

const groupList = ref<InstanceType<typeof GroupList> | null>(null);
async function createGroup() {
  if (rc.activeSejour == null) return;

  const res = await controller.SejoursCreateGroupe({
    "id-sejour": rc.activeSejour.Sejour.Id,
  });
  if (res == undefined) return;
  controller.showMessage("Groupe ajouté avec succès.");

  rc.activeSejour.Groups = (rc.activeSejour.Groups || []).concat(res);
  nextTick(() => groupList.value?.startEdit(res));
}

async function updateGroup(group: Group) {
  const res = await controller.SejoursUpdateGroupe(group);
  if (res == undefined) return;
  controller.showMessage("Groupe modifié avec succès.");

  const l = rc.activeSejour?.Groups || [];
  const index = l.findIndex((g) => g.Id == group.Id);
  l[index] = group;
}

async function deleteGroup(group: Group) {
  const res = await controller.SejoursDeleteGroupe({ "id-group": group.Id });
  if (res == undefined) return;
  controller.showMessage("Groupe supprimé avec succès.");

  const l = rc.activeSejour?.Groups || [];
  rc.activeSejour!.Groups = l.filter((g) => g.Id != group.Id);
}

const showClientLinkDialog = ref(false);

async function copyClientLink() {
  const link = rc.activeSejour!.ExportClientURL;
  try {
    await navigator.clipboard.writeText(link);
    controller.showMessage("Lien copié dans le presse-papier.");
  } catch (e) {
    controller.onError("Presse-papier", `Impossible de copier le lien: ${e}`);
  }
}
</script>
