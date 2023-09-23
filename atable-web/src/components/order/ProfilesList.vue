<template>
  <v-card
    title="Fournisseurs"
    subtitle="Les fournisseurs sont regroupés par profil, et un profil peut être associé au séjour courant."
  >
    <v-dialog
      :model-value="toShowDetails != null"
      @update:model-value="toShowDetails = null"
      fullscreen
    >
      <ProfileMapping
        :profile="toShowDetails"
        v-if="toShowDetails != null"
        @close="toShowDetails = null"
      ></ProfileMapping>
    </v-dialog>

    <v-dialog
      :model-value="toEdit != null"
      @update:model-value="toEdit = null"
      max-width="600px"
    >
      <v-card title="Modifier le profil" v-if="toEdit != null">
        <v-card-text>
          <v-row>
            <v-col>
              <v-text-field
                density="compact"
                variant="outlined"
                v-model="toEdit.Name"
                label="Nom"
              >
              </v-text-field>
            </v-col>
          </v-row>
        </v-card-text>
        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn @click="updateProfile" color="success" variant="text"
            >Enregistrer</v-btn
          >
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!--  -->

    <v-dialog
      :model-value="toDelete != null"
      @update:model-value="toDelete = null"
      max-width="600px"
    >
      <v-card title="Supprimer le profil" v-if="toDelete != null">
        <v-card-text>
          Confirmez-vous la suppression du profil {{ toDelete.Profile.Name }} et
          de tous ses fournisseurs ? <br />
          Cette opération est irréversible.
        </v-card-text>
        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn @click="deleteProfile" color="red" variant="text"
            >Supprimer</v-btn
          >
        </v-card-actions>
      </v-card>
    </v-dialog>

    <template v-slot:append>
      <v-btn @click="addProfil"
        >Ajouter un profil
        <template v-slot:prepend>
          <v-icon color="green">mdi-plus</v-icon>
        </template>
      </v-btn>
    </template>
    <v-card-text>
      <v-list>
        <v-list-item
          v-if="!profiles.length"
          subtitle="Aucun profil n'est encore défini."
        >
        </v-list-item>
        <v-list-item
          v-for="(profile, index) in profiles"
          :key="index"
          :title="profile.Profile.Name"
          :subtitle="formatSuppliers(profile.Suppliers)"
          @click="toShowDetails = profile"
        >
          <template v-slot:prepend>
            <v-btn
              icon
              size="x-small"
              class="mr-4"
              @click.stop="setDefaultProfile(profile.Profile.Id)"
            >
              <v-icon
                :color="
                  sejourCourant?.IdProfile.IdProfile == profile.Profile.Id
                    ? 'primary'
                    : 'grey-lighten-2'
                "
                >mdi-heart</v-icon
              >
            </v-btn>
          </template>
          <template v-slot:append>
            <v-btn
              icon
              size="x-small"
              class="mx-1"
              @click.stop="toEdit = copy(profile.Profile)"
              :disabled="profile.Profile.IdOwner != controller.idUser"
            >
              <v-icon>mdi-pencil</v-icon>
            </v-btn>
            <v-btn
              icon
              size="x-small"
              @click.stop="toDelete = copy(profile)"
              :disabled="profile.Profile.IdOwner != controller.idUser"
              class="mx-1"
            >
              <v-icon color="red">mdi-delete</v-icon>
            </v-btn>
          </template>
        </v-list-item>
      </v-list>
    </v-card-text>
  </v-card>
</template>

<script lang="ts" setup>
import type {
  ProfileHeader,
  Profile,
  Suppliers,
  IdProfile,
} from "@/logic/api_gen";
import { controller, copy, formatSuppliers } from "@/logic/controller";
import { onMounted } from "vue";
import { ref } from "vue";
import ProfileMapping from "./ProfileMapping.vue";
import { computed } from "vue";
import { id } from "vuetify/lib/locale/index.mjs";

// const props = defineProps<{}>();

const emit = defineEmits<{}>();

const profiles = ref<ProfileHeader[]>([]);

onMounted(fetchProfiles);

const sejourCourant = ref(controller.activeSejour?.Sejour || null);

async function fetchProfiles() {
  const res = await controller.OrderGetProfiles();
  if (res === undefined) return;
  profiles.value = res || [];
}

async function addProfil() {
  const res = await controller.OrderCreateProfile();
  if (res === undefined) return;
  profiles.value.splice(0, 0, { Profile: res, Suppliers: {} });

  // start edit
  toEdit.value = copy(res);
}

const toEdit = ref<Profile | null>(null);
async function updateProfile() {
  const pr = toEdit.value;
  if (pr == null) return;
  toEdit.value = null;
  const res = await controller.OrderUpdateProfile(pr);
  if (res === undefined) return;

  controller.showMessage("Profil modifié avec succès.");

  const toUpdate = profiles.value.find((pro) => pro.Profile.Id == pr.Id)!;
  toUpdate.Profile = pr;
}

const toDelete = ref<ProfileHeader | null>(null);
async function deleteProfile() {
  const pr = toDelete.value;
  if (pr == null) return;
  toDelete.value = null;
  const res = await controller.OrderDeleteProfile({ id: pr.Profile.Id });
  if (res === undefined) return;

  controller.showMessage("Profil supprimé avec succès.");

  profiles.value = profiles.value.filter(
    (pro) => pro.Profile.Id != pr.Profile.Id
  );
}

const toShowDetails = ref<ProfileHeader | null>(null);

async function setDefaultProfile(idProfile: IdProfile) {
  const sej = sejourCourant.value;
  if (sej === null) return;
  const res = await controller.OrderSetDefaultProfile({
    IdProfile: idProfile,
    IdSejour: sej.Id,
  });
  if (res === undefined) return;

  sej.IdProfile = { Valid: true, IdProfile: idProfile };

  controller.showMessage("Fournisseurs par défaut modifié avec succès.");
}
</script>
