const rhythms = [
  { name:'Arrocha', bpm:92, file:'Arrocha.wav', cover:'arrocha_img.png', description:'Balanço envolvente e marcante' },
  { name:'Arrocha Rápido', bpm:118, file:'arrocha_rapido.wav', cover:'arrocha_rapido_img.png', description:'Energia para levantar o salão' },
  { name:'Vanera', bpm:124, file:'Vanera.wav', cover:'vanera_img.png', description:'Cadência gaúcha dançante' },
  { name:'Bachata', bpm:126, file:'Bachata.wav', cover:'bachata_img.png', description:'Leve, latina e romântica' },
  { name:'Guarânia', bpm:78, file:'guarania.wav', cover:'guarania_img.png', description:'Andamento lento e expressivo' },
  { name:'Pagode', bpm:96, file:'pagode.wav', cover:'pagode_img.png', description:'Swing brasileiro essencial' },
  { name:'Pagode Rápido', bpm:116, file:'pagode_rapido.wav', cover:'pagode_rapido_img.png', description:'Swing acelerado e festivo' },
  { name:'Axé Lento', bpm:104, file:'axe_lento.wav', cover:'axe_lento_img.png', description:'Groove baiano cadenciado' },
  { name:'Axé Rápido', bpm:138, file:'axe_rapido.wav', cover:'axe_rapido_img.png', description:'Pulso forte de carnaval' },
  { name:'Pop Rock', bpm:112, file:'pop_rock.wav', cover:'pop_rock_img.png', description:'Base firme e versátil' },
  { name:'Pop Rock 2', bpm:128, file:'pop_rock_2.wav', cover:'pop_rock_2_img.png', description:'Variação moderna e pulsante' },
  { name:'Xote', bpm:94, file:'xote.wav', cover:'xote_img.png', description:'Forró macio para dançar junto' },
  { name:'Reggae', bpm:82, file:'reggae.wav', cover:'reggae_img.png', description:'Contratempo leve e relaxado' }
];

const $ = selector => document.querySelector(selector);
const player = $('#player');
const state = { index:0, bpm:rhythms[0].bpm, playing:false, fading:false };

function makeWave(){
  const wave = $('#waveform');
  for(let i=0;i<30;i++){
    const bar=document.createElement('i');
    bar.style.setProperty('--h',`${9 + ((i*17)%28)}px`);
    bar.style.setProperty('--d',`${-(i%7)*.09}s`);
    wave.appendChild(bar);
  }
}

function makeBars(){
  return `<span class="bars">${[7,14,10,18,8].map((h,i)=>`<i style="--b:${h}px;animation-delay:-${i*.1}s"></i>`).join('')}</span>`;
}

function renderLibrary(){
  $('#rhythmGrid').innerHTML = rhythms.map((r,i)=>`<button class="rhythm-card ${i===state.index?'active':''}" data-index="${i}"><span class="cover" style="background-image:url('public/covers/${r.cover}')"></span><span class="card-shade"></span><span class="number">${String(i+1).padStart(2,'0')}</span>${makeBars()}<span class="card-copy"><strong>${r.name}</strong><small>${r.bpm} BPM ORIGINAL</small></span></button>`).join('');
  document.querySelectorAll('.rhythm-card').forEach(card=>card.addEventListener('click',()=>selectRhythm(Number(card.dataset.index),state.playing)));
}

function updateTempo(bpm){
  state.bpm=Math.max(70,Math.min(160,Math.round(bpm)));
  $('#bpmValue').textContent=state.bpm;
  $('#tempoRange').value=state.bpm;
  player.playbackRate=state.bpm/rhythms[state.index].bpm;
}

async function selectRhythm(index, autoplay=false){
  state.index=(index+rhythms.length)%rhythms.length;
  const rhythm=rhythms[state.index];
  player.src=`public/audio/${encodeURIComponent(rhythm.file)}`;
  $('#currentRhythm').textContent=rhythm.name;
  $('#currentDescription').textContent=rhythm.description;
  updateTempo(rhythm.bpm);
  renderLibrary();
  if(autoplay) await play();
}

async function play(){
  try{await player.play();state.playing=true;document.body.classList.add('playing');$('#play').setAttribute('aria-label','Pausar')}catch(error){console.error('Não foi possível iniciar o áudio.',error)}
}

function pause(hard=false){
  const fade=$('#fadeToggle').checked&&!hard;
  if(!fade){player.pause();finishPause();return}
  state.fading=true;
  const start=player.volume,started=performance.now();
  const step=now=>{
    const progress=Math.min(1,(now-started)/600);
    player.volume=start*(1-progress);
    if(progress<1&&state.fading) requestAnimationFrame(step);
    else{player.pause();player.volume=Number($('#volume').value);finishPause()}
  };
  requestAnimationFrame(step);
}

function finishPause(){state.playing=false;state.fading=false;document.body.classList.remove('playing');$('#play').setAttribute('aria-label','Reproduzir')}
function toggle(){state.playing?pause():play()}

$('#play').addEventListener('click',toggle);
$('#previous').addEventListener('click',()=>selectRhythm(state.index-1,state.playing));
$('#next').addEventListener('click',()=>selectRhythm(state.index+1,state.playing));
$('#tempoDown').addEventListener('click',()=>updateTempo(state.bpm-1));
$('#tempoUp').addEventListener('click',()=>updateTempo(state.bpm+1));
$('#tempoRange').addEventListener('input',event=>updateTempo(event.target.value));
$('#volume').addEventListener('input',event=>player.volume=Number(event.target.value));
$('#openSettings').addEventListener('click',()=>$('#settingsDialog').showModal());
document.addEventListener('keydown',event=>{if(event.code==='Space'&&!$('#settingsDialog').open){event.preventDefault();toggle()}if(event.code==='ArrowRight')selectRhythm(state.index+1,state.playing);if(event.code==='ArrowLeft')selectRhythm(state.index-1,state.playing)});
player.addEventListener('error',()=>finishPause());

function hideSplash(){
  const splash=$('#splash');
  if(!splash||splash.classList.contains('is-hidden')) return;
  splash.classList.add('is-hidden');
  window.setTimeout(()=>splash.remove(),500);
}

$('#splash').addEventListener('click',hideSplash);
window.addEventListener('load',()=>window.setTimeout(hideSplash,1400));

makeWave();
renderLibrary();
selectRhythm(0);
player.volume=.9;
if('serviceWorker' in navigator) window.addEventListener('load',()=>navigator.serviceWorker.register('sw.js'));
