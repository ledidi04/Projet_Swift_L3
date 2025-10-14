import Foundation

// MARK: - Classes
class Matiere {
    let nom: String
    let coefficient: Double
    
    init(nom: String, coefficient: Double) {
        self.nom = nom
        self.coefficient = coefficient
    }
}

class Classe {
    let nom: String
    let frais: Double
    var matieres: [Matiere]
    
    init(nom: String, frais: Double) {
        self.nom = nom
        self.frais = frais
        self.matieres = []
    }
}

class Etudiant {
    let id: Int
    let nom: String
    let prenom: String
    let adresse: String
    let sexe: String
    let classe: Classe
    var notes: [String: [Double]]
    var montantPaye: Double
    
    var montantDu: Double { classe.frais }
    var resteAPayer: Double { montantDu - montantPaye }
    var estEnRegle: Bool { resteAPayer <= 0 }
    
    init(id: Int, nom: String, prenom: String, adresse: String, sexe: String, classe: Classe) {
        self.id = id
        self.nom = nom
        self.prenom = prenom
        self.adresse = adresse
        self.sexe = sexe
        self.classe = classe
        self.notes = [:]
        self.montantPaye = 0
    }
}

class Transaction {
    let id: Int
    let description: String
    let montant: Double
    let type: String
    let etudiantId: Int?
    let date: Date
    
    init(id: Int, description: String, montant: Double, type: String, etudiantId: Int? = nil) {
        self.id = id
        self.description = description
        self.montant = montant
        self.type = type
        self.etudiantId = etudiantId
        self.date = Date() // Date actuelle par défaut
    }
}

class GestionScolaire {
    var classes: [Classe] = []
    var etudiants: [Etudiant] = []
    var transactions: [Transaction] = []
    private var nextEtudiantId = 1
    private var nextTransactionId = 1
    
    // MARK: - Fonctions utilitaires 
    func saisirChampObligatoire(_ nomChamp: String) -> String {
        while true {
            print("\(nomChamp):", terminator: " ")
            if let valeur = readLine()?.trimmingCharacters(in: .whitespaces), !valeur.isEmpty {
                return valeur
            }
            print("Le champ '\(nomChamp)' est obligatoire.")
        }
    }
    
    func saisirDouble(_ message: String) -> Double {
        while true {
            print("\(message):", terminator: " ")
            if let input = readLine(), let valeur = Double(input), valeur > 0 {
                return valeur
            }
            print("Veuillez entrer un nombre valide supérieur à 0.")
        }
    }
    
    func saisirInt(_ message: String) -> Int {
        while true {
            print("\(message):", terminator: " ")
            if let input = readLine(), let valeur = Int(input), valeur > 0 {
                return valeur
            }
            print("Veuillez entrer un nombre entier valide.")
        }
    }
    
    func demanderContinuer(action: String) -> Bool {
        print("\nVoulez-vous \(action) à nouveau ? (o/n):", terminator: " ")
        if let reponse = readLine()?.lowercased() {
            return reponse == "o" || reponse == "oui"
        }
        return false
    }
    
    // MARK: - Configuration
    func afficherClasses() {
        print("\n=== CLASSES DISPONIBLES ===")
        if classes.isEmpty {
            print("Aucune classe configurée")
        } else {
            for (index, classe) in classes.enumerated() {
                print("\(index + 1). \(classe.nom) - \(classe.frais) HTG")
            }
        }
    }
    
    func choisirClasse() -> Classe? {
        guard !classes.isEmpty else {
            print("Aucune classe disponible.")
            return nil
        }
        
        afficherClasses()
        print("\nChoisir une classe (numéro):", terminator: " ")
        
        guard let input = readLine(), 
              let choix = Int(input),
              choix >= 1 && choix <= classes.count else {
            print("Choix invalide. Veuillez sélectionner un numéro valide.")

            return nil
        }
        return classes[choix - 1]
    }
    
    func configurerClasse() {
        var continuer = true
        while continuer {
            print("\n=== CONFIGURATION D'UNE NOUVELLE CLASSE ===")
            let nomClasse = saisirChampObligatoire("Nom de la classe")
            
            // Vérifier si la classe existe déjà
            if classes.contains(where: { $0.nom.lowercased() == nomClasse.lowercased() }) {
                print("Une classe avec ce nom existe déjà.")
                continuer = demanderContinuer(action: "configurer une classe")
                continue
            }
            
            let frais = saisirDouble("Frais annuels (HTG)")
            classes.append(Classe(nom: nomClasse, frais: frais))
            print("Classe '\(nomClasse)' configurée avec \(frais) HTG")
            continuer = demanderContinuer(action: "configurer une classe")
        }
    }
    
    func configurerMatieresPourClasse() {
        guard !classes.isEmpty else {
            print("\nAucune classe configurée. Veuillez d'abord configurer une classe.")
            return
        }
        
        var continuer = true
        while continuer {
            print("\n=== CONFIGURATION DES MATIÈRES ===")
            guard let classe = choisirClasse() else { 
                continuer = demanderContinuer(action: "configurer les matières")
                continue
            }
            
            var ajouterMatiere = true
            while ajouterMatiere {
                print("\n--- NOUVELLE MATIÈRE ---")
                let nomMatiere = saisirChampObligatoire("Nom de la matière")
                
                // Vérifier si la matière existe déjà
                if classe.matieres.contains(where: { $0.nom.lowercased() == nomMatiere.lowercased() }) {
                    print("Cette matière existe déjà dans la classe.")
                } else {
                    let coefficient = saisirDouble("Coefficient")
                    let nouvelleMatiere = Matiere(nom: nomMatiere, coefficient: coefficient)
                    classe.matieres.append(nouvelleMatiere)
                    print("Matière '\(nomMatiere)' ajoutée avec coefficient \(coefficient)")
                }
                
                print("Ajouter une autre matière ? (o/n):", terminator: " ")
                ajouterMatiere = (readLine()?.lowercased() == "o")
            }
            continuer = demanderContinuer(action: "configurer les matières")
        }
    }
    
    // MARK: - Gestion des étudiants
    func ajouterEtudiant() {
        guard !classes.isEmpty else {
            print("\n❌ Aucune classe configurée. Veuillez d'abord configurer une classe.")
            return
        }
        
        var continuer = true
        while continuer {
            print("\n=== INSCRIPTION D'UN NOUVEL ÉTUDIANT ===")
            let nom = saisirChampObligatoire("Nom de famille")
            let prenom = saisirChampObligatoire("Prénom")
            let adresse = saisirChampObligatoire("Adresse complète")
            
            var sexe = ""
            while sexe.isEmpty {
                print("Sexe (M/F):", terminator: " ")
                if let saisie = readLine()?.uppercased(), saisie == "M" || saisie == "F" {
                    sexe = saisie
                } else {
                    print("Sexe invalide. Veuillez saisir M pour Masculin ou F pour Féminin.")
                }
            }
            
            guard let classe = choisirClasse() else {
                continuer = demanderContinuer(action: "ajouter un étudiant")
                continue
            }
            
            let etudiant = Etudiant(
                id: nextEtudiantId,
                nom: nom,
                prenom: prenom,
                adresse: adresse,
                sexe: sexe,
                classe: classe
            )
            
            etudiants.append(etudiant)
            print("\nÉTUDIANT INSCRIT AVEC SUCCÈS")
            print("ID: \(nextEtudiantId) | Nom: \(prenom) \(nom) | Sexe: \(sexe) | Classe: \(classe.nom)")
            nextEtudiantId += 1
            continuer = demanderContinuer(action: "ajouter un étudiant")
        }
    }


    //fonction permettant de Lister Tous les Etudiants
    func listerEtudiants() {
        print("\nLISTE DES ÉTUDIANTS (\(etudiants.count))")
        guard !etudiants.isEmpty else {
            print("Aucun étudiant enregistré.")
            return
        }
        
        for etudiant in etudiants {
            let moyenne = calculerMoyenneGenerale(etudiantId: etudiant.id) ?? 0
            let moyenneAffichage = moyenne > 0 ? String(format: "%.2f", moyenne) : "Aucune note"
            let statutPaiement = etudiant.estEnRegle ? "Oui" : "Non"
            print("ID: \(etudiant.id) | \(etudiant.prenom) \(etudiant.nom) | \(etudiant.classe.nom) | Moyenne: \(moyenneAffichage) | En règle avec l'économat : \(statutPaiement)")
        }
    }


    //fonction Permettant de Lister Les Etudiants Par Classe
    func listerEtudiantsParClasse() {
        guard !classes.isEmpty else {
            print("\nAucune classe configurée.")
            return
        }
        
        var continuer = true
        while continuer {
            print("\n=== LISTER ÉTUDIANTS PAR CLASSE ===")
            // Afficher les classes sans frais
            print("\n=== CLASSES DISPONIBLES ===")
            if classes.isEmpty {
                print("Aucune classe configurée")
            } else {
                for (index, classe) in classes.enumerated() {
                    print("\(index + 1). \(classe.nom)")
                }
            }

            print("\nChoisir une classe (numéro):", terminator: " ")
            guard let input = readLine(), 
                let choix = Int(input),
                choix >= 1 && choix <= classes.count else {
                print("Choix invalide.")
                continuer = demanderContinuer(action: "lister les étudiants")
                continue
            }
            let classe = classes[choix - 1]
            
            let etudiantsClasse = etudiants.filter { $0.classe.nom == classe.nom }
            print("\n=== ÉTUDIANTS DE \(classe.nom) (\(etudiantsClasse.count)) ===")
            
            guard !etudiantsClasse.isEmpty else {
                print("Aucun étudiant dans cette classe.")
                continuer = demanderContinuer(action: "lister les étudiants")
                continue
            }
            
            for etudiant in etudiantsClasse {
                let moyenne = calculerMoyenneGenerale(etudiantId: etudiant.id) ?? 0
                let moyenneAffichage = moyenne > 0 ? String(format: "%.2f", moyenne) : "Aucune note"
                print("""
                ID: \(etudiant.id)
                Nom: \(etudiant.prenom) \(etudiant.nom)
                Sexe: \(etudiant.sexe == "M" ? "Masculin" : "Féminin")
                Moyenne: \(moyenneAffichage)
                ---
                """)
            }
            continuer = demanderContinuer(action: "lister les étudiants")
        }
    }
    
    // MARK: - Gestion des notes
    func rechercherEtudiant(id: Int) -> Etudiant? {
        return etudiants.first { $0.id == id }
    }
    
    func calculerMoyenneGenerale(etudiantId: Int) -> Double? {
        guard let etudiant = rechercherEtudiant(id: etudiantId) else {
            return nil
        }
        
        let matieres = etudiant.classe.matieres
        guard !matieres.isEmpty else { return nil }
        
        var totalPoints = 0.0
        var totalCoefficients = 0.0
        
        for matiere in matieres {
            guard let notes = etudiant.notes[matiere.nom], !notes.isEmpty else { continue }
            
            let moyenne = notes.reduce(0, +) / Double(notes.count)
            totalPoints += moyenne * matiere.coefficient
            totalCoefficients += matiere.coefficient
        }
        return totalCoefficients > 0 ? totalPoints / totalCoefficients : nil
    }
    
    func ajouterNote() {
            guard !etudiants.isEmpty else {
                print("\n❌ Aucun étudiant enregistré.")
                return
            }
            
            var continuer = true
            while continuer {
                print("\n=== AJOUTER DES NOTES ===")
                let id = saisirInt("ID étudiant")


                guard let etudiant = rechercherEtudiant(id: id) else {
                    print("Aucun étudiant trouvé avec l'ID \(id)")
                    continuer = demanderContinuer(action: "ajouter des notes")
                    continue
                }
                
                let matieres = etudiant.classe.matieres
                guard !matieres.isEmpty else {
                    print("Aucune matière définie pour la classe \(etudiant.classe.nom)")
                    continuer = demanderContinuer(action: "ajouter des notes")
                    continue
                }
                
                print("Étudiant: \(etudiant.prenom) \(etudiant.nom) - Classe: \(etudiant.classe.nom)")
                
                for matiere in matieres {
                    var notes: [Double] = []
                    var ajouterNote = true
                    
                    print("\n--- Matière: \(matiere.nom) ---")
                    while ajouterNote {
                        let note = saisirDouble("Note (0-100)")
                        
                        if note >= 0 && note <= 100 {
                            notes.append(note)
                            print("Note \(String(format: "%.1f", note)) ajoutée. Notes actuelles: \(notes.map { String(format: "%.1f", $0) })")
                        } else {
                            print("Note invalide. Doit être entre 0 et 100.")
                        }
                        
                        print("\nAjouter une autre note pour cette matière ? (o/n):", terminator: " ")
                        ajouterNote = (readLine()?.lowercased() == "o")
                    }
                    
                    if !notes.isEmpty {
                        etudiant.notes[matiere.nom] = notes
                    }
                }
                print("\nToutes les notes ont été saisies pour \(etudiant.prenom) \(etudiant.nom)")
                continuer = demanderContinuer(action: "ajouter des notes")
            }
        }
        
        // MARK: - Gestion financière
        func ajouterTransaction(description: String, montant: Double, type: String, etudiantId: Int? = nil) {
            let transaction = Transaction(
                id: nextTransactionId, 
                description: description, 
                montant: montant, 
                type: type, 
                etudiantId: etudiantId
            )
            transactions.append(transaction)
            nextTransactionId += 1
            print("SUCCES: Transaction #\(nextTransactionId-1) enregistrée")
        }
        
        func calculerSolde() -> Double {
            return transactions.reduce(0.0) { solde, transaction in
                return transaction.type == "entree" ? solde + transaction.montant : solde - transaction.montant
            }
        }
        
        func afficherSolde() {
             let solde = calculerSolde()
            let statut = solde >= 0 ? "Positif" : "Négatif"
            print("\nSOLDE ACTUEL: \(String(format: "%.2f", solde)) HTG (\(statut))")
        }
        
        func enregistrerPaiementEtudiant() {
            guard !etudiants.isEmpty else {
                print("\nAucun étudiant enregistré.")
                return
            }
            
            var continuer = true
            while continuer {
                print("\n=== PAIEMENT ÉTUDIANT ===")
                let id = saisirInt("ID étudiant")
                
                guard let etudiant = rechercherEtudiant(id: id) else {
                    print("Aucun étudiant trouvé avec l'ID \(id)")
                    continuer = demanderContinuer(action: "enregistrer un paiement")
                    continue
                }
                
                let reste = etudiant.resteAPayer
                print("\nÉtudiant: \(etudiant.prenom) \(etudiant.nom)")
                print("Montant dû: \(String(format: "%.2f", etudiant.montantDu)) HTG")
                print("Déjà payé: \(String(format: "%.2f", etudiant.montantPaye)) HTG")
                print("Reste à payer: \(String(format: "%.2f", reste)) HTG")
                
                guard reste > 0 else {
                    print("Cet étudiant a déjà payé tous ses frais.")
                    continuer = demanderContinuer(action: "enregistrer un paiement")
                    continue

                }
                
                let montant = saisirDouble("Montant du paiement")
                
                guard montant <= reste else {
                    print("Montant trop élevé! Le reste à payer est de \(String(format: "%.2f", reste)) HTG")
                    continuer = demanderContinuer(action: "enregistrer un paiement")
                    continue
                }
                
                etudiant.montantPaye += montant
                ajouterTransaction(
                    description: "Paiement de \(etudiant.prenom) \(etudiant.nom)", 
                    montant: montant, 
                    type: "entree", 
                    etudiantId: etudiant.id
                )
                print("Paiement enregistré! Nouveau reste: \(String(format: "%.2f", reste - montant)) HTG")
                continuer = demanderContinuer(action: "enregistrer un paiement")
            }
        }
        
        func afficherNotesPourMatiere() {
        guard !classes.isEmpty else {
            print("\nAucune classe configuree.")
            return
        }
        
        var continuer = true
        while continuer {
            print("\n=== NOTES POUR UNE MATIERE ===")
            guard let classe = choisirClasse() else {
                continuer = demanderContinuer(action: "afficher les notes")
                continue
            }
            
            let matieres = classe.matieres
            guard !matieres.isEmpty else {
                print("Aucune matiere definie pour cette classe.")
                continuer = demanderContinuer(action: "afficher les notes")
                continue
            }
            
            print("\n=== MATIERES DISPONIBLES ===")
            for (index, matiere) in matieres.enumerated() {
                print("\(index + 1). \(matiere.nom)")
            }
            
            print("Choisir une matiere (numero):", terminator: " ")
            guard let input = readLine(), 
                let choix = Int(input),
                choix >= 1 && choix <= matieres.count else {
                print("Choix invalide.")
                continuer = demanderContinuer(action: "afficher les notes")
                continue
            }
            
            let matiereSelectionnee = matieres[choix - 1]
            let etudiantsClasse = etudiants.filter { $0.classe.nom == classe.nom }
            
            print("\n=== NOTES POUR \(matiereSelectionnee.nom.uppercased()) ===")
            
            var totalAvecNotes = 0
            var sommeMoyennes = 0.0
            
            for etudiant in etudiantsClasse {
                guard let notes = etudiant.notes[matiereSelectionnee.nom], !notes.isEmpty else {
                    print("\(etudiant.prenom) \(etudiant.nom): Aucune note")
                    continue
                }
                
                let moyenne = notes.reduce(0, +) / Double(notes.count)
                sommeMoyennes += moyenne
                totalAvecNotes += 1
                
                // Format d'affichage avec nom de l'étudiant et notes
                let notesFormatees = notes.map { String(format: "%.0f", $0) }.joined(separator: ", ")
                print("\(etudiant.prenom) \(etudiant.nom) - \(matiereSelectionnee.nom) : \(notesFormatees)")
            }
            
            if totalAvecNotes > 0 {
                print("\n=== STATISTIQUES ===")
                print("Moyenne de la classe: \(String(format: "%.2f", sommeMoyennes / Double(totalAvecNotes)))")
                print("Etudiants avec notes: \(totalAvecNotes)/\(etudiantsClasse.count)")
            } else {
                print("Aucune note enregistree pour cette matiere.")
            }
            continuer = demanderContinuer(action: "afficher les notes")
        }
    }
    
    // MARK: - Menus
    func menuEtudiants() {
        while true {
            print("""
            \n=== GESTION ÉTUDIANTS ===

            1. Configurer une classe
            2. Configurer les matières
            3. Ajouter un étudiant
            4. Lister tous les étudiants
            5. Lister par classe
            6. Ajouter une note
            7. Afficher les notes
            8. Retour
            
            Choix: 
            """, terminator: " ")
            
            guard let choix = readLine() else { continue }
            
            switch choix {
            case "1": configurerClasse()
            case "2": configurerMatieresPourClasse()
            case "3": ajouterEtudiant()
            case "4": listerEtudiants()
            case "5": listerEtudiantsParClasse()
            case "6": ajouterNote()
            case "7": afficherNotesPourMatiere()
            case "8": return
            default: print("❌ Choix invalide")
            }
        }
    }
    
    func menuEconomat() {
        while true {
            print("""
            \n=== GESTION ÉCONOMAT ===
            1. Enregistrer paiement étudiant
            2. Entrée d'argent
            3. Sortie d'argent
            4. Liste des transactions
            5. Voir solde
            6. Retour
            
            Votre choix: 
            """, terminator: " ")
            
            guard let choix = readLine() else { continue }
            
            switch choix {
            case "1": enregistrerPaiementEtudiant()
            case "2": 
                let description = saisirChampObligatoire("Description")
                let montant = saisirDouble("Montant")
                ajouterTransaction(description: description, montant: montant, type: "entree")
            case "3": 
                let description = saisirChampObligatoire("Description")
                let montant = saisirDouble("Montant")
                let solde = calculerSolde()
                if montant <= solde {
                    ajouterTransaction(description: description, montant: montant, type: "sortie")
                } else {
                    print("Solde insuffisant! Solde actuel: \(String(format: "%.2f", solde)) HTG")
                }
            case "4": afficherTransactions()
            case "5": afficherSolde()
            case "6": return
            default: print("Choix invalide")
            }
        }
    }
    
   func afficherTransactions() {
        print("\n=== LISTE DES TRANSACTIONS (\(transactions.count)) ===")
        if transactions.isEmpty {
            print("Aucune transaction")
        } else {
            // Formateur de date
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy HH:mm"
            
            for transaction in transactions {
                let signe = transaction.type == "entree" ? "+" : "-"
                let etudiantInfo: String
                if let etudiantId = transaction.etudiantId,
                let etudiant = rechercherEtudiant(id: etudiantId) {
                    etudiantInfo = " (\(etudiant.prenom) \(etudiant.nom))"
                } else {
                    etudiantInfo = ""
                }
                
                let dateFormatee = formatter.string(from: transaction.date)
                print("\(transaction.id) | \(dateFormatee) | \(signe)\(String(format: "%.2f", transaction.montant)) HTG | \(etudiantInfo)")
            }
        }

    }
    
    // MARK: - Point d'entrée
    func demarrer() {
        while true {
            print("""
            \n=== SYSTÈME DE GESTION SCOLAIRE ===
            1. Gestion des Étudiants
            2. Gestion de l'Économat
            3. Quitter
            
            Choix: 
            """, terminator: " ")
            
            guard let choix = readLine() else { continue }
            
            switch choix {
            case "1": menuEtudiants()
            case "2": menuEconomat()
            case "3": 
                print("Au revoir!")
                return
            default: print("Choix invalide")
            }
        }
    }
}

// Lancement du programme
let gestion = GestionScolaire()
gestion.demarrer()
