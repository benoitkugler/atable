<template>
  <v-dialog
    :model-value="showInscriptionValidated"
    @update:model-value="removeInscriptionValidated"
    max-width="600px"
  >
    <v-card title="Inscription validée" color="success">
      <v-card-text>
        Votre inscription a bien été validée. <br />
        Vous pouvez vous connecter avec vos nouveaux identifiants.
      </v-card-text>
    </v-card>
  </v-dialog>

  <v-dialog v-model="showResetDone" max-width="600px">
    <v-card>
      <v-card-title class="bg-info"
        >Réinitialisation du mot de passe</v-card-title
      >
      <v-card-text>
        Un mail contenant votre nouveau mot de passe a été envoyé à l'adresse
        <div style="text-align: center">
          <i>{{ settings.Mail }}</i>
        </div>
        Vous pourrez le modifier via le pannel de réglages de votre compte.
      </v-card-text>
    </v-card>
  </v-dialog>

  <v-dialog v-model="showSuccessInscription" max-width="600px">
    <v-card title="Inscription enregistrée" color="success">
      <v-card-text>
        Merci pour votre inscription ! <br />
        Un mail de confirmation vous a été envoyé à l'adresse
        <i>{{ settings.Mail }}</i
        >. <br />
        Merci de suivre le lien présent dans le mail pour valider votre
        inscription.
      </v-card-text>
    </v-card>
  </v-dialog>

  <v-row class="my-1 mx-6 pb-3 fill-height" justify="center">
    <v-col
      cols="12"
      sm="6"
      align-self="center"
      class="d-none d-sm-flex"
      v-if="mode == 'connection'"
    >
      <v-card>
        <v-card-title class="bg-secondary rounded">
          Bienvenue sur À table !
        </v-card-title>
        <v-card-text class="py-3"
          >À table vous permet d'organiser vos recettes et vos menus, pour
          faciliter la cuisine en collectivité.
        </v-card-text>
        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn
            color="secondary"
            variant="elevated"
            @click="
              mode = 'inscription';
              showPassword = true;
            "
          >
            S'inscrire
          </v-btn>
          <v-spacer></v-spacer>
        </v-card-actions>
      </v-card>
    </v-col>

    <v-col cols="12" sm="6" align-self="center">
      <v-card>
        <v-card-title class="bg-primary rounded">
          {{ mode == "inscription" ? "S'inscrire" : "  Se connecter" }}
        </v-card-title>
        <v-progress-linear
          indeterminate
          v-show="isLoading"
          color="primary"
        ></v-progress-linear>
        <v-form
          class="px-3 mt-4"
          @keyup.enter="mode == 'inscription' ? inscription() : connection()"
        >
          <v-row>
            <v-col>
              <v-text-field
                density="comfortable"
                variant="outlined"
                label="Mail"
                v-model="settings.Mail"
                type="email"
                name="email"
                :hint="
                  mode == 'inscription'
                    ? 'Adresse utiilisée comme identifiant'
                    : ''
                "
                required
                :error="error.Error != '' && !error.IsPasswordError"
                :error-messages="
                  error.Error != '' && !error.IsPasswordError
                    ? [error.Error]
                    : ''
                "
              ></v-text-field>
            </v-col>
          </v-row>
          <v-row>
            <v-col>
              <v-text-field
                density="comfortable"
                variant="outlined"
                label="Mot de passe"
                v-model="settings.Password"
                :append-inner-icon="showPassword ? 'mdi-eye' : 'mdi-eye-off'"
                :type="showPassword ? 'text' : 'password'"
                name="password"
                @click:append-inner="showPassword = !showPassword"
                :error="error.Error != '' && error.IsPasswordError"
                :error-messages="
                  error.Error != '' && error.IsPasswordError
                    ? [error.Error]
                    : ''
                "
                :hide-details="mode == 'inscription'"
              ></v-text-field>
            </v-col>
          </v-row>
          <v-row v-if="mode == 'inscription'">
            <v-col>
              <v-text-field
                density="comfortable"
                variant="outlined"
                label="Pseudonyme"
                v-model="settings.Pseudo"
                name="pseudo"
                hint="Nom affiché aux autres utilisateurs"
              ></v-text-field>
            </v-col>
          </v-row>
        </v-form>
        <v-card-actions class="mt-2">
          <v-btn v-if="mode == 'inscription'" @click="mode = 'connection'"
            >Retour</v-btn
          >
          <v-btn
            v-else
            v-show="error.Error != ''"
            :disabled="!isEmailValid"
            @click="resetPassword"
          >
            Mot de passe oublié ?
          </v-btn>
          <v-spacer></v-spacer>
          <v-btn
            color="primary"
            variant="elevated"
            :disabled="!areCredencesValid"
            @click="mode == 'inscription' ? inscription() : connection()"
          >
            {{ mode == "inscription" ? "S'inscrire" : "  Se connecter" }}
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-col>
  </v-row>
</template>

<script setup lang="ts">
import { AskInscriptionIn, AskInscriptionOut, IdUser } from "@/logic/api_gen";
import { controller } from "@/logic/controller";
import { reactive } from "vue";
import { ref } from "vue";
import { computed } from "vue";

const emit = defineEmits<{
  (e: "loggin", idUser: IdUser, token: string, pseudo: string): void;
}>();

const showInscriptionValidated = window.location.search.includes(
  "show-success-inscription"
);
function removeInscriptionValidated() {
  window.location.search = "";
}

const mode = ref<"inscription" | "connection">("connection");
const mathMode = ref(true);

const settings = reactive<AskInscriptionIn>({
  Mail: "",
  Password: "",
  Pseudo: "",
});
const showPassword = ref(false);
const error = reactive<AskInscriptionOut>({
  Error: "",
  IsPasswordError: false,
});
const showSuccessInscription = ref(false);
const isLoading = ref(false);

const areCredencesValid = computed(
  () => !isLoading.value && isEmailValid.value && settings.Password != ""
);

const isEmailValid = computed(
  () => settings.Mail.includes("@") && settings.Mail.includes(".")
);

async function inscription() {
  if (!areCredencesValid.value) return;

  isLoading.value = true;
  const res = await controller.AskInscription(settings);
  isLoading.value = false;
  if (res == undefined) {
    return;
  }
  error.Error = res.Error;
  error.IsPasswordError = res.IsPasswordError;
  if (error.Error == "") {
    showSuccessInscription.value = true;
  }
}

async function connection() {
  if (!areCredencesValid.value) return;

  const res = await controller.Loggin({
    Mail: settings.Mail,
    Password: settings.Password,
  });
  if (res == undefined) {
    return;
  }

  error.Error = res.Error;
  error.IsPasswordError = res.IsPasswordError;
  if (error.Error) return;

  emit("loggin", res.Id, res.Token, res.Pseudo);
}

let showResetDone = ref(false);
async function resetPassword() {
  const res = await controller.UserResetPassword({ mail: settings.Mail });
  if (res == undefined) return;
  showResetDone.value = true;
}
</script>

<style></style>
