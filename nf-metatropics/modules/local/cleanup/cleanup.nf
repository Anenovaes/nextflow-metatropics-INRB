process CLEANUP {
    label 'process_single'
    
    input:
    path versions_file
    path final_report
    path read_counts_csv
    
    script:
    """
    if [ "${workflow.containerEngine}" = "docker" ]; then
        docker ps -aq | xargs -r docker rm -f
        docker images -q | xargs -r docker rmi -f
        echo "Docker cleanup completed"
    else
        echo "Docker cleanup skipped as Docker is not the container engine"
    fi
    """
}
