function setup(htmlComponent) {

    // Add a listener to the event "ThemeChanged" that will be sent from 
    // MATLAB.
    htmlComponent.addEventListener("ThemeChanged", onThemeChanged)

    function onThemeChanged(event) {

        // Find the styles and HTML elements that will be updated when the
        // theme changes.
        let bodyStyle = document.body.style
        let codeInputBlocks = document.getElementsByClassName("codeinput")
        let keywordSpans = document.getElementsByClassName("keyword")
        let commentSpans = document.getElementsByClassName("comment")
        let stringSpans = document.getElementsByClassName("string")
        let typesectionSpans = document.getElementsByClassName("typesection")

        // Update the appropriate colors.
        if (event.Data == "Light Theme") {
            bodyStyle.color = "#000000"
            bodyStyle.background = "#FFFFFF"
            for (let k = 0; k < codeInputBlocks.length; k++) {
                codeInputBlocks[k].style.background = "#F7F7F7"
            }
            for (let k = 0; k < keywordSpans.length; k++) {
                keywordSpans[k].style.color = "#0000FF"
            }
            for (let k = 0; k < commentSpans.length; k++) {
                commentSpans[k].style.color = "#228B22"
            }
            for (let k = 0; k < stringSpans.length; k++) {
                stringSpans[k].style.color = "#A020F0"
            }
            for (let k = 0; k < typesectionSpans.length; k++) {
                typesectionSpans[k].style.color = "#A0522D"
            }
        } else {
            bodyStyle.color = "#D9D9D9"
            bodyStyle.background = "#121212"
            for (let k = 0; k < codeInputBlocks.length; k++) {
                codeInputBlocks[k].style.background = "#121212"
            }
            for (let k = 0; k < keywordSpans.length; k++) {
                keywordSpans[k].style.color = "#7DA9FF"
            }
            for (let k = 0; k < commentSpans.length; k++) {
                commentSpans[k].style.color = "#94EF84"
            }
            for (let k = 0; k < stringSpans.length; k++) {
                stringSpans[k].style.color = "#D694FF"
            }
            for (let k = 0; k < typesectionSpans.length; k++) {
                typesectionSpans[k].style.color = "#CB845D"
            }
        }
    }

}