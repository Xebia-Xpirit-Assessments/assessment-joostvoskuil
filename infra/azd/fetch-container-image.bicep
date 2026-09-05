@description('Whether the container app already exists. When false, no image can be read yet.')
param exists bool

@description('The container app name to read the current image from.')
param name string

resource existingApp 'Microsoft.App/containerApps@2024-03-01' existing = if (exists) {
  name: name
}

// azd's standard "exists" pattern: preserves the image azd deploy last set so azd provision never resets it.
output containers array = exists ? existingApp!.properties.template.containers : []
