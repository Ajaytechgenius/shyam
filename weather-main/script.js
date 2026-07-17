let currentWeatherType = null;
let rotateInterval = null;

function requestLocation(){
navigator.geolocation.getCurrentPosition(async position => {

document.getElementById("locationScreen").classList.add("hidden");
document.getElementById("app").classList.remove("hidden");

const lat = position.coords.latitude;
const lon = position.coords.longitude;

const res = await fetch(
`https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current_weather=true`
);

const data = await res.json();
const weather = data.current_weather;

document.getElementById("temp").innerText =
weather.temperature + "°C";

currentWeatherType = mapWeather(weather.weathercode);
document.getElementById("condition").innerText = currentWeatherType;

loadBackground(currentWeatherType);

startRotation();

});
}

function mapWeather(code){
if(code <= 3) return "clear";
if(code <= 67) return "rain";
if(code <= 77) return "snow";
if(code >= 95) return "thunder";
return "clouds";
}

function loadBackground(type){

if(document.getElementById("useCustom").checked){
let video = localStorage.getItem("video_" + type);
if(video){
document.getElementById("bgVideo").src = video;
return;
}
}

if(document.getElementById("useApi").checked){
fetchFromClovverr(type);
}

}

function saveCustomVideo(){
const file = document.getElementById("videoUpload").files[0];
const type = document.getElementById("weatherTypeSelect").value;

const reader = new FileReader();
reader.onload = function(e){
localStorage.setItem("video_" + type, e.target.result);
alert("Saved!");
}
reader.readAsDataURL(file);
}

function saveApiKey(){
const key = document.getElementById("apiKeyInput").value;
localStorage.setItem("clovverr_key", key);
alert("API Key Saved");
}

async function fetchFromClovverr(type){
const key = localStorage.getItem("clovverr_key");
if(!key) return;

const res = await fetch(`https://api.clovverr.com/search?query=${type}`,{
headers:{ Authorization:key }
});

const data = await res.json();
const videoUrl = data.results[0].video;

document.getElementById("bgVideo").src = videoUrl;
}

function startRotation(){
rotateInterval = setInterval(()=>{
if(currentWeatherType)
loadBackground(currentWeatherType);
},120000);
}

function toggleSettings(){
document.getElementById("settingsPanel").classList.toggle("hidden");
}
