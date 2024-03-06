const yaml = require("js-yaml")
const fs = require("fs")

const yamlText = fs.readFileSync('_index.yml', {encoding: "utf8"})
const body: any = yaml.load(yamlText)
const text = JSON.stringify(body, null, 2) // JSONに変換

fs.writeFile('_index.json', text, 'utf8', (err: any)=>{
  if(err !== null){
    // エラー処理
    return false
  }
})