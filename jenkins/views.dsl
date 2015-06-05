deliveryPipelineView('Continuous Delivery Pipeline') {
    pipelineInstances(2)
    columns(1)
    updateInterval(5)
    enableManualTriggers()
    pipelines {
        component('Image Selector Application', 'ISA-poll-version-control')
        component('Image Slide Show', 'DockerStage')
        component('Instagram Image Processing', 'InstagramImageGet')
    }
}
