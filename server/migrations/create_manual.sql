-- instructions to run once at DB creation
--  1) Admin user account
--  2) Common ingredients

INSERT INTO users (id, mail, PASSWORD, isAdmin, pseudo)
    VALUES (1, 'admin@intendance.fr', 'admin', TRUE, 'Administrateur');

-- I_Empty       IngredientKind = iota // Autre
-- I_Legumes                           // Fruits et légumes
-- I_Feculents                         // Féculents
-- I_Viandes                           // Viandes, poissons
-- I_Epicerie                          // Épicerie
-- I_Laitages                          // Laitages
-- I_Boulangerie                       // Boulangerie

INSERT INTO ingredients (name, kind)
    VALUES ('Pommes de terre', 1), ('Brocoli', 1), ('Malt', 1), ('Avoine', 2), ('Riz', 2), ('Maïs', 4), ('Popcorn', 0), ('Pommes', 1), ('Abricots', 1), ('Avocats', 1), ('Bananes', 1), ('Cassis', 1), ('Groseilles', 1), ('Dattes', 1), ('Figues', 1), ('Raisins', 1), ('Goyaves', 1), ('Kiwis', 1), ('Litchis', 1), ('Mangues', 1), ('Melons', 1), ('Oranges', 1), ('Papayes', 1), ('Pastèques', 1), ('Pêches', 1), ('Nectarines', 1), ('Poires', 1), ('Ananas', 1), ('Prunes', 1), ('Citrouilles', 1), ('Coing', 1), ('Myrtilles', 1), ('Mûres', 1), ('Cerises', 1), ('Framboises', 1), ('Fraises', 1), ('Pamplemousses', 1), ('Kumquats', 1), ('Citrons', 1), ('Mandarines', 1), ('Guacamole', 4), ('Vanille', 4), ('Champignons', 1), ('Haricots rouges', 4), ('Haricots', 1), ('Pois', 1), ('Soja', 1), ('Chicorée', 1), ('Houblon', 1), ('Laurier', 1), ('Olives', 1), ('Thé', 4), ('Cresson', 1), ('Miel', 4), ('Macaroni', 2), ('Seigle', 1), ('Vin blanc', 4), ('Vinaigre', 4), ('Vinaigre balsamique', 4), ('Ciboulette (botte)', 4), ('Endives', 1), ('Poireaux', 1), ('Oignons', 1), ('Échalotes', 1), ('Orge', 2), ('Chous', 1), ('Chou-fleurs', 1), ('Raifort', 1), ('Moutarde', 4), ('Radis', 1), ('Navets', 1), ('Tomates', 1), ('Poivrons', 1), ('Concombres', 1), ('Carottes', 1), ('Panais', 1), ('Asperges', 1), ('Manioc', 1), ('Aubergines', 1), ('Grenades', 1), ('Epinards', 1), ('Roquette', 1), ('Lentilles', 2), ('Millet', 2), ('Blé', 2), ('Cardons', 1), ('Caroubes', 1), ('Courges', 1), ('Jujubes', 1), ('Quinoa', 2), ('Epeautre', 2), ('Levure (sachet)', 4), ('Courgettes', 1), ('Semoule', 2), ('Boulgour', 2), ('Salade verte', 1), ('Saumon (pavés)', 3), ('Saumon fumé (tranches)', 3), ('Poisson', 3), ('Maquereau', 3), ('Anchois', 3), ('Merlan', 3), ('Chevreuil', 3), ('Boeuf', 3), ('Poulet', 3), ('Jambon (tranches)', 3), ('Jambon (dés)', 3), ('Agneau', 3), ('Steaks hachés', 3), ('Viande hachée', 3), ('Saucisses', 3), ('Mouton', 3), ('Porc', 3), ('Lard', 3), ('Lardons', 3), ('Dinde', 3), ('Flétan', 3), ('Cerf', 3), ('Crabe', 3), ('Hareng', 3), ('Oeufs', 3), ('Écrevisse', 3), ('Truite', 3), ('Crevette', 3), ('Sanglier', 3), ('Lotte', 3), ('Calmar', 3), ('Caille', 3), ('Turbot', 3), ('Caviar', 3), ('Morue', 3), ('Thon', 3), ('Lapin', 3), ('Escargot', 3), ('Cannelle', 4), ('Butternuts', 1), ('Tilleul', 4), ('Oseille', 4), ('Pistaches', 4), ('Châtaignes', 4), ('Câpres', 4), ('Curcuma', 4), ('Safran', 4), ('Curry', 4), ('Poivre', 4), ('Persil', 4), ('Origan', 4), ('Gingembre', 4), ('Cumin', 4), ('Farine', 4), ('Sucre', 4), ('Céleris', 1), ('Cardamome', 4), ('Carvi', 4), ('Anis', 4), ('Noix', 4), ('Noisettes', 4), ('Cacahuètes', 4), ('Cornichons', 4), ('Jus de citron', 4), ('Huile', 4), ('Huile d''olive', 4), ('Pulpe de tomate', 4), ('Ratatouille (cuisinée)', 4), ('Rillettes', 4), ('Rosette', 4), ('Chocolat', 4), ('Cacao', 4), ('Amandes', 4), ('Thym', 4), ('Estragon', 4), ('Sauge', 4), ('Chips', 4), ('Romarin', 4), ('Rhubarbe', 1), ('Menthe', 4), ('Ail (gousse)', 1), ('Fenouils', 1), ('Aneth', 4), ('Sésame', 4), ('Cerfeuil', 4), ('Sarrasin', 4), ('Basilic', 4), ('Angélique', 4), ('Ketchup', 4), ('Sauce béchamel', 4), ('Sauce burger', 4), ('Mayonnaise', 4), ('Café', 4), ('Jus de fruits', 0), ('Céréales', 4), ('Confiture', 4), ('Coriandre', 4), ('Kéfir', 5), ('Féta', 5), ('Mozzarella', 5), ('Kiri', 5), ('Fromage de chèvre', 5), ('Fromage burger', 5), ('Crème fraiche', 5), ('Lait', 5), ('Yaourt nature', 5), ('Fromage râpé', 5), ('Parmesan râpé', 5), ('Comté', 5), ('Beurre', 5), ('Caramel', 6), ('Tortilla', 6), ('Meringue', 6), ('Guimauve', 6), ('Biscuits', 6), ('Lasagnes', 2), ('Pâtes', 2), ('Spaghetis', 2), ('Tagliatelles', 2), ('Galettes faritas', 6), ('Pain', 6), ('Pain de mie (tranches)', 6), ('Pains burgers', 6), ('Pains ronds', 6), ('Baguettes', 6);

SELECT
    setval('users_id_seq', (
            SELECT
                MAX(id)
            FROM users));

SELECT
    setval('ingredients_id_seq', (
            SELECT
                MAX(id)
            FROM ingredients));

