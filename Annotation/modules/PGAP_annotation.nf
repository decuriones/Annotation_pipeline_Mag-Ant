#!/usr/bin/env nextflow

/*
 * PGAP annotation pipeline
 */

process PGAP_annotation {

    input:
    path seq
    val genus
    val project

    output:
    path "${seq.simpleName}_pgap_annotation"

    script:
    """
    module load apptainer
    
    # ═══════════════════════════════════════════════════════════
    # IMPORTANT : Mettre notre wrapper en PREMIER dans le PATH
    # ═══════════════════════════════════════════════════════════
    
    # Le répertoire bin/ de Nextflow est automatiquement dans le PATH,
    # mais on s'assure qu'il est en PREMIER
    export PATH=\${PWD}/../../../bin:\${PATH}
    
    # Vérifier que notre wrapper est utilisé (optionnel, pour débug)
    echo "Using apptainer from: \$(which apptainer)"
    
    # ═══════════════════════════════════════════════════════════
    # EXÉCUTION PGAP (va utiliser notre wrapper automatiquement)
    # ═══════════════════════════════════════════════════════════


    GENUS="${genus}"
    genus_bsh="\${GENUS#g__}"      # remove GTDB prefix if present
    if [ "\$genus_bsh" == "Escherichia" ]; then
        echo "Genus is set to default value: Escherichia (E. coli) \n\t Please check the corrected genus after pgap run with --taxcheck --auto-correct-tax"
        /lustre06/project/6066427/software/singularity_images/pgap.py -r \
        --container-name pgap_build7983.sif \
        -D apptainer \
        --container-path /lustre06/project/6066427/software/singularity_images/pgap_build7983.sif \
        -o ${seq.simpleName}_pgap_annotation \
        -g '${seq}' \
        -s "\$genus_bsh" \
        --ignore-all-errors \
        --no-internet \
        --no-self-update \
        --taxcheck \
        --auto-correct-tax
        2>&1 | tee pgap.log || {
            echo "PGAP failed with exit code \$?"
            cat pgap.log
            exit 1
        }
        
    else
        /lustre06/project/6066427/software/singularity_images/pgap.py -r \
        --container-name pgap_build7983.sif \
        -D apptainer \
        --container-path /lustre06/project/6066427/software/singularity_images/pgap_build7983.sif \
        -o ${seq.simpleName}_pgap_annotation \
        -g '${seq}' \
        -s "\$genus_bsh" \
        --ignore-all-errors \
        --no-internet \
        --no-self-update
        2>&1 | tee pgap.log || {
            echo "PGAP failed with exit code \$?"
            cat pgap.log
            exit 1
        }

    fi
        """
}