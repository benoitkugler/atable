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

      <v-row justify="center">
        <v-col cols="6">
          <v-list-item-title> Format du fichier CSV </v-list-item-title>
          <br />
          <v-list-item-subtitle>
            La première ligne d'une recette suit le format : <br /><br />
            Nom de la recette, catégorie de plat, nombre de personnes
            <br /><br />
            Les catégories de plat acceptées sont : <br />
            entree, platPrincipal, dessert
          </v-list-item-subtitle>
        </v-col>
        <v-col cols="auto">
          <table style="border-collapse: collapse">
            <tr>
              <td style="border: 1px solid black" class="pa-1">Recette 1</td>
              <td style="border: 1px solid black" class="pa-1">
                platPrincipal
              </td>
              <td style="border: 1px solid black" class="pa-1">10</td>
            </tr>
            <tr>
              <td style="border: 1px solid black" class="pa-1">Ingrédient 1</td>
              <td style="border: 1px solid black" class="pa-1">Quantité</td>
              <td style="border: 1px solid black" class="pa-1">Unité</td>
            </tr>
            <tr>
              <td style="border: 1px solid black" class="pa-1">Ingrédient 2</td>
              <td style="border: 1px solid black" class="pa-1">Quantité</td>
              <td style="border: 1px solid black" class="pa-1">Unité</td>
            </tr>
            <tr>
              <td style="border: 1px solid black">&nbsp;</td>
              <td style="border: 1px solid black"></td>
              <td style="border: 1px solid black"></td>
            </tr>
            <tr>
              <td style="border: 1px solid black" class="pa-1">Recette 2</td>
              <td style="border: 1px solid black" class="pa-1">entree</td>
              <td style="border: 1px solid black" class="pa-1">5</td>
            </tr>
            <tr>
              <td style="border: 1px solid black" class="pa-1">Ingrédient 1</td>
              <td style="border: 1px solid black" class="pa-1">Quantité</td>
              <td style="border: 1px solid black" class="pa-1">Unité</td>
            </tr>
            <tr>
              <td style="border: 1px solid black" class="pa-1">Ingrédient 2</td>
              <td style="border: 1px solid black" class="pa-1">Quantité</td>
              <td style="border: 1px solid black" class="pa-1">Unité</td>
            </tr>
          </table>
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
