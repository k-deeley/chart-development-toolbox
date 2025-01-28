function setup(htmlComponent) {

    window.htmlComponent = htmlComponent

}

function handleClick(command) {

    window.htmlComponent.sendEventToMATLAB("LinkClicked", command)

}