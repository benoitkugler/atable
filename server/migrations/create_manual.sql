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

INSERT INTO ingredients (name, kind, OWNER)
    VALUES ('Pommes de terre', 1, 1),
    --
    ('Brocoli', 1, 1),
    --
    ('Malt', 1, 1),
    --
    ('Avoine', 2, 1),
    --
    ('Riz', 2, 1),
    --
    ('Maïs', 4, 1),
    --
    ('Popcorn', 0, 1),
    --
    ('Glace', 0, 1),
    --
    ('Pommes', 1, 1),
    --
    ('Abricots', 1, 1),
    --
    ('Avocats', 1, 1),
    --
    ('Bananes', 1, 1),
    --
    ('Cassis', 1, 1),
    --
    ('Groseilles', 1, 1),
    --
    ('Dattes', 1, 1),
    --
    ('Figues', 1, 1),
    --
    ('Raisins', 1, 1),
    --
    ('Goyaves', 1, 1),
    --
    ('Kiwis', 1, 1),
    --
    ('Litchis', 1, 1),
    --
    ('Mangues', 1, 1),
    --
    ('Melons', 1, 1),
    --
    ('Oranges', 1, 1),
    --
    ('Papayes', 1, 1),
    --
    ('Pastèques', 1, 1),
    --
    ('Pêches', 1, 1),
    --
    ('Nectarines', 1, 1),
    --
    ('Poires', 1, 1),
    --
    ('Ananas', 1, 1),
    --
    ('Prunes', 1, 1),
    --
    ('Citrouilles', 1, 1),
    --
    ('Coing', 1, 1),
    --
    ('Myrtilles', 1, 1),
    --
    ('Mûres', 1, 1),
    --
    ('Cerises', 1, 1),
    --
    ('Framboises', 1, 1),
    --
    ('Fraises', 1, 1),
    --
    ('Pamplemousses', 1, 1),
    --
    ('Kumquats', 1, 1),
    --
    ('Citrons', 1, 1),
    --
    ('Mandarines', 1, 1),
    --
    ('Guacamole', 4, 1),
    --
    ('Vanille', 4, 1),
    --
    ('Champignons', 1, 1),
    --
    ('Haricots rouges', 4, 1),
    --
    ('Haricots', 1, 1),
    --
    ('Pois', 1, 1),
    --
    ('Soja', 1, 1),
    --
    ('Chicorée', 1, 1),
    --
    ('Houblon', 1, 1),
    --
    ('Laurier', 1, 1),
    --
    ('Olives', 1, 1),
    --
    ('Thé', 4, 1),
    --
    ('Cresson', 1, 1),
    --
    ('Miel', 4, 1),
    --
    ('Macaroni', 2, 1),
    --
    ('Seigle', 1, 1),
    --
    ('Vin blanc', 4, 1),
    --
    ('Vinaigre', 4, 1),
    --
    ('Vinaigre balsamique', 4, 1),
    --
    ('Ciboulette (botte)', 4, 1),
    --
    ('Endives', 1, 1),
    --
    ('Poireaux', 1, 1),
    --
    ('Oignons', 1, 1),
    --
    ('Échalotes', 1, 1),
    --
    ('Orge', 2, 1),
    --
    ('Chous', 1, 1),
    --
    ('Chou-fleurs', 1, 1),
    --
    ('Raifort', 1, 1),
    --
    ('Moutarde', 4, 1),
    --
    ('Radis', 1, 1),
    --
    ('Navets', 1, 1),
    --
    ('Tomates', 1, 1),
    --
    ('Poivrons', 1, 1),
    --
    ('Concombres', 1, 1),
    --
    ('Carottes', 1, 1),
    --
    ('Panais', 1, 1),
    --
    ('Asperges', 1, 1),
    --
    ('Manioc', 1, 1),
    --
    ('Aubergines', 1, 1),
    --
    ('Grenades', 1, 1),
    --
    ('Epinards', 1, 1),
    --
    ('Roquette', 1, 1),
    --
    ('Lentilles', 2, 1),
    --
    ('Millet', 2, 1),
    --
    ('Blé', 2, 1),
    --
    ('Cardons', 1, 1),
    --
    ('Caroubes', 1, 1),
    --
    ('Courges', 1, 1),
    --
    ('Jujubes', 1, 1),
    --
    ('Quinoa', 2, 1),
    --
    ('Epeautre', 2, 1),
    --
    ('Levure (sachet)', 4, 1),
    --
    ('Courgettes', 1, 1),
    --
    ('Semoule', 2, 1),
    --
    ('Boulgour', 2, 1),
    --
    ('Salade verte', 1, 1),
    --
    ('Saumon (pavés)', 3, 1),
    --
    ('Saumon fumé (tranches)', 3, 1),
    --
    ('Poisson', 3, 1),
    --
    ('Maquereau', 3, 1),
    --
    ('Anchois', 3, 1),
    --
    ('Merlan', 3, 1),
    --
    ('Chevreuil', 3, 1),
    --
    ('Boeuf', 3, 1),
    --
    ('Poulet', 3, 1),
    --
    ('Jambon (tranches)', 3, 1),
    --
    ('Jambon (dés)', 3, 1),
    --
    ('Agneau', 3, 1),
    --
    ('Steaks hachés', 3, 1),
    --
    ('Viande hachée (boeuf)', 3, 1),
    --
    ('Saucisses', 3, 1),
    --
    ('Mouton', 3, 1),
    --
    ('Porc', 3, 1),
    --
    ('Lard', 3, 1),
    --
    ('Lardons', 3, 1),
    --
    ('Dinde', 3, 1),
    --
    ('Flétan', 3, 1),
    --
    ('Cerf', 3, 1),
    --
    ('Crabe', 3, 1),
    --
    ('Hareng', 3, 1),
    --
    ('Oeufs', 3, 1),
    --
    ('Écrevisse', 3, 1),
    --
    ('Truite', 3, 1),
    --
    ('Crevette', 3, 1),
    --
    ('Sanglier', 3, 1),
    --
    ('Lotte', 3, 1),
    --
    ('Calmar', 3, 1),
    --
    ('Caille', 3, 1),
    --
    ('Turbot', 3, 1),
    --
    ('Caviar', 3, 1),
    --
    ('Morue', 3, 1),
    --
    ('Thon', 3, 1),
    --
    ('Lapin', 3, 1),
    --
    ('Escargot', 3, 1),
    --
    ('Cannelle', 4, 1),
    --
    ('Butternuts', 1, 1),
    --
    ('Tilleul', 4, 1),
    --
    ('Oseille', 4, 1),
    --
    ('Pistaches', 4, 1),
    --
    ('Châtaignes', 4, 1),
    --
    ('Câpres', 4, 1),
    --
    ('Curcuma', 4, 1),
    --
    ('Safran', 4, 1),
    --
    ('Curry', 4, 1),
    --
    ('Poivre', 4, 1),
    --
    ('Persil', 4, 1),
    --
    ('Origan', 4, 1),
    --
    ('Gingembre', 4, 1),
    --
    ('Cumin', 4, 1),
    --
    ('Farine', 4, 1),
    --
    ('Sucre', 4, 1),
    --
    ('Céleris', 1, 1),
    --
    ('Cardamome', 4, 1),
    --
    ('Carvi', 4, 1),
    --
    ('Anis', 4, 1),
    --
    ('Noix', 4, 1),
    --
    ('Noisettes', 4, 1),
    --
    ('Cacahuètes', 4, 1),
    --
    ('Cornichons', 4, 1),
    --
    ('Jus de citron', 4, 1),
    --
    ('Huile', 4, 1),
    --
    ('Huile d''olive', 4, 1),
    --
    ('Pulpe de tomate', 4, 1),
    --
    ('Ratatouille (cuisinée)', 4, 1),
    --
    ('Rillettes', 4, 1),
    --
    ('Rosette', 4, 1),
    --
    ('Chocolat', 4, 1),
    --
    ('Cacao', 4, 1),
    --
    ('Amandes', 4, 1),
    --
    ('Thym', 4, 1),
    --
    ('Estragon', 4, 1),
    --
    ('Sauge', 4, 1),
    --
    ('Chips', 4, 1),
    --
    ('Romarin', 4, 1),
    --
    ('Rhubarbe', 1, 1),
    --
    ('Menthe', 4, 1),
    --
    ('Ail (gousse)', 1, 1),
    --
    ('Fenouils', 1, 1),
    --
    ('Aneth', 4, 1),
    --
    ('Sésame', 4, 1),
    --
    ('Cerfeuil', 4, 1),
    --
    ('Sarrasin', 4, 1),
    --
    ('Basilic', 4, 1),
    --
    ('Angélique', 4, 1),
    --
    ('Ketchup', 4, 1),
    --
    ('Sauce béchamel', 4, 1),
    --
    ('Sauce burger', 4, 1),
    --
    ('Mayonnaise', 4, 1),
    --
    ('Café', 4, 1),
    --
    ('Jus de fruits', 0, 1),
    --
    ('Céréales', 4, 1),
    --
    ('Confiture', 4, 1),
    --
    ('Crème de marron', 4, 1),
    --
    ('Coriandre', 4, 1),
    --
    ('Kéfir', 5, 1),
    --
    ('Féta', 5, 1),
    --
    ('Mozzarella', 5, 1),
    --
    ('Kiri', 5, 1),
    --
    ('Fromage de chèvre', 5, 1),
    --
    ('Fromage burger', 5, 1),
    --
    ('Crème fraîche', 5, 1),
    --
    ('Lait', 5, 1),
    --
    ('Fromage blanc', 5, 1),
    --
    ('Yaourt nature', 5, 1),
    --
    ('Yaourt aux fruits', 5, 1),
    --
    ('Fromage râpé', 5, 1),
    --
    ('Parmesan râpé', 5, 1),
    --
    ('Comté', 5, 1),
    --
    ('Beurre', 5, 1),
    --
    ('Caramel', 6, 1),
    --
    ('Tortilla', 6, 1),
    --
    ('Meringue', 6, 1),
    --
    ('Guimauve', 6, 1),
    --
    ('Biscuits', 6, 1),
    --
    ('Lasagnes', 2, 1),
    --
    ('Pâtes', 2, 1),
    --
    ('Spaghetis', 2, 1),
    --
    ('Tagliatelles', 2, 1),
    --
    ('Galettes faritas', 6, 1),
    --
    ('Pain de mie (tranches)', 6, 1),
    --
    ('Pains burgers', 6, 1),
    --
    ('Pains ronds', 6, 1),
    --
    ('Baguettes', 6, 1),
    --
    ('Veau', 3, 1),
    --
    ('Chair à saucisse', 3, 1),
    --
    ('Sauce vinaigrette', 4, 1),
    --
    ('Chocolat au lait', 4, 1),
    --
    ('Sirop', 4, 1),
    --
    ('Herbes de provence', 4, 1),
    --
    ('Beurre salé', 5, 1),
    --
    ('Maïzena', 5, 1),
    --
    ('Sucre glace', 4, 1),
    --
    ('Muscade', 4, 1),
    --
    ('Sauce tomate', 4, 1),
    --
    ('Pâte feuilletée', 4, 1),
    --
    ('Fromages (secs)', 5, 1);

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

SELECT
    setval('receipes_id_seq', (
            SELECT
                MAX(id)
            FROM receipes));

