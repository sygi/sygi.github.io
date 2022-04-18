import { load_three } from '../three.js';
class ChooseTransferCapture {
    constructor() {
        this.buttons = ["Transfer attribute", "Capture attribute"];
    }
    process(clicked_button) {
        console.log("clicked", clicked_button);
        let image_src = null;
        let alt_text = null;
        if (clicked_button.indexOf("Transfer") != -1) {
          image_src = "../images/geometry_nodes/transfer2.png";
          alt_text = "Transfer attribute";
          load_three("../data/geometry_nodes/transfer_attribute.json");
        } else if (clicked_button.indexOf("Capture") != -1) {
          image_src = "../images/geometry_nodes/capture2.png";
          alt_text = "Capture attribute";
          load_three("../data/geometry_nodes/capture_attribute.json");
        }

        const new_link = document.createElement("a");
        new_link.href = image_src;
        const new_image = document.createElement('img');
        new_image.style = "width:100%";
        new_image.src = image_src;
        new_image.alt = alt_text;
        new_link.appendChild(new_image);
        
        const image_place = document.getElementsByClassName("capture_transfer_nodes")[0];
        if (image_place.firstChild) {
          image_place.removeChild(image_place.firstChild);
        }
        image_place.appendChild(new_link);
    }
}

window.button_options = { "capture_transfer_option": new ChooseTransferCapture() };
