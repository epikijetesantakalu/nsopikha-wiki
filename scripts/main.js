import { loadEpiku } from "./epiku.js";
const pathRoot = location.pathname.includes("nsopikha-wiki") ? "/nsopikha-wiki" : ""; //ローカル環境と実環境で挙動を統一
console.log(pathRoot);
insertTemplate("header", "header");
insertTemplate("stub", "stub");
insertTemplate("footer", "footer");
document.body.style.display = 'block'; //読み込みが終わったら表示
window.onload = () => {
    const searchButton = document.getElementById("searchButton");
    const searchText = document.getElementById("search");
    searchButton.addEventListener("click", (e) => {
        window.location.assign(`${pathRoot}/specials/search.html?text=${searchText.value}`);
    });
    loadEpiku(pathRoot);
};
function insertTemplate(file, className) {
    const req = new XMLHttpRequest();
    req.open("GET", `${pathRoot}/layouts/${file}.html`, true);
    req.onreadystatechange = () => {
        if (req.readyState === 4 && req.status === 200) {
            const HTML = req.responseText;
            const elements = document.getElementsByClassName(className);
            Array.from(elements).forEach((e) => {
                e.insertAdjacentHTML("afterbegin", HTML);
            });
        }
    };
    req.send();
}
