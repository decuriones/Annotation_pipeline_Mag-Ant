# Mag-Ant(Annotation_pipeline)
Pipeline developped for standardized annotation and quality assessement of cyanobacterial MAGs. Strong emphasis is put on detection of exogenous contigs such as viral contaminant, as the end goal of this pipeline is to propose output ready for pangenomic analysis.

Usage :

 * Profil choice = standard, pgap or bakta, the default profile advised is bakta as it is the default annotation tool (and the only one working as for now)

Arguments :
    
    // Path to the fasta sequences in an array format
    seq_list = []
    
    // Path to metadata file containing the genus information for PGAP annotation
    tax_gtdb = ''
    
    // Project name for taxonomy collection output
    project = 'Annotation_project'
    
    // Annotation tool to use (PGAP or Bakta)
    annotation_tool = 'Bakta' // Default to Bakta, but can be set to PGAP using the pgap profile
    
    // Boolean parameter to decide whether to run Antismash annotation
    antismash = true // Default to true, but can be set to false if Antismash annotation is not needed
    
    // Boolean parameter to decide whether to run Busco annotation
    busco = true // Default to true, but can be set to false if Busco annotation is not needed
