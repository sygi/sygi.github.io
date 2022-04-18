function construct_buttons(id) {
    // TODO: use document fragment or something
    function get_joint_callback(clicked_button, buttons) {
        return () => {
            for (var button of buttons) {
                if (clicked_button == button.innerHTML) {
                    button.classList.add("option-selected");
                }
                else {
                    button.classList.remove("option-selected");
                }
            }
            window.button_options[id].process(clicked_button);
        };
    }
    ;
    var result_buttons = new Array();
    let available_buttons = window.button_options[id].buttons.filter((x, i, a) => a.indexOf(x) == i);
    if (available_buttons.length != window.button_options[id].buttons.length) {
        console.warn("Buttons", window.button_options[id].buttons, "are not unique");
    }
    window.button_options[id].buttons.forEach((option) => {
        let button = document.createElement('button');
        button.className = "option";
        button.innerHTML = option;
        result_buttons.push(button);
    });
    for (var button of result_buttons) {
        button.addEventListener("click", get_joint_callback(button.innerHTML, result_buttons));
    }
    return result_buttons;
}
document.addEventListener("DOMContentLoaded", function () {
    // TODO: check that the options are pairwise different.
    let options_elements = document.getElementsByClassName("options");
    let ids_in_html = Array.from(options_elements).map((x) => x.id).sort();
    let ids_in_ts = Object.keys(window.button_options).sort();
    if (JSON.stringify(ids_in_html) != JSON.stringify(ids_in_ts)) {
        console.warn("HTML defines these placeholders: ", ids_in_html, "but ts defines these", ids_in_ts);
    }
    for (var option_placeholder of options_elements) {
        for (let button of construct_buttons(option_placeholder.id)) {
            option_placeholder.appendChild(button);
        }
        option_placeholder.children[0].click();
    }
});
