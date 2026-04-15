document.documentElement.classList.remove("no-js");

const copyButton = document.getElementById("copyCommandButton");
const installCommand = document.getElementById("installCommand");
const typeTarget = document.getElementById("typeTarget");
const typeCursor = document.getElementById("typeCursor");
const typeSound = document.getElementById("typeSound");

if (copyButton && installCommand) {
  copyButton.addEventListener("click", () => {
    const command = installCommand.textContent.trim();
    const url = command.replace(/^open\s+/, "");

    if (url) {
      window.open(url, "_blank", "noopener,noreferrer");
    }
  });
}

if (typeTarget && typeCursor) {
  const phrase = typeTarget.textContent.trim();
  let audioUnlocked = false;
  let audioContext = null;
  let audioBuffer = null;
  let audioDataPromise = null;
  let loopToken = 0;
  let unlockPromise = null;

  const wait = (ms) => new Promise((resolve) => window.setTimeout(resolve, ms));

  const primeAudioData = () => {
    if (!typeSound) {
      return null;
    }

    if (!audioDataPromise) {
      const source = typeSound.currentSrc || typeSound.src;
      if (!source) {
        return null;
      }

      audioDataPromise = fetch(source)
        .then((response) => {
          if (!response.ok) {
            throw new Error(`Failed to load audio: ${response.status}`);
          }
          return response.arrayBuffer();
        })
        .catch(() => null);
    }

    return audioDataPromise;
  };

  const loadAudioBuffer = async () => {
    if (!typeSound || audioBuffer) {
      return audioBuffer;
    }

    if (!audioContext) {
      const Context = window.AudioContext || window.webkitAudioContext;
      if (!Context) {
        return null;
      }
      audioContext = new Context();
    }

    const arrayBuffer = await primeAudioData();
    if (!arrayBuffer) {
      return null;
    }

    audioBuffer = await audioContext.decodeAudioData(arrayBuffer.slice(0));
    return audioBuffer;
  };

  const unlockAudio = async () => {
    if (audioUnlocked) {
      return;
    }

    if (!unlockPromise) {
      unlockPromise = (async () => {
        try {
          await loadAudioBuffer();
          if (audioContext && audioContext.state === "suspended") {
            await audioContext.resume();
          }
          audioUnlocked = true;
          loopToken += 1;
          typeTarget.textContent = "";
          typeCursor.classList.remove("is-typing");
          runTypeLoop(loopToken);
        } catch (error) {
          audioUnlocked = false;
        }
      })();
    }

    await unlockPromise;
  };

  const playKeySound = (character) => {
    if (!audioUnlocked || !audioContext || !audioBuffer || !character.trim()) {
      return;
    }

    const source = audioContext.createBufferSource();
    const gain = audioContext.createGain();

    source.buffer = audioBuffer;
    gain.gain.value = 0.2;
    source.playbackRate.value = 0.985 + Math.random() * 0.03;

    source.connect(gain);
    gain.connect(audioContext.destination);
    source.start(0);
  };

  const runTypeLoop = async (token) => {
    await wait(320);

    while (token === loopToken) {
      typeCursor.classList.add("is-typing");

      for (let i = 1; i <= phrase.length; i += 1) {
        if (token !== loopToken) {
          return;
        }
        const character = phrase[i - 1];
        typeTarget.textContent = phrase.slice(0, i);
        playKeySound(character);
        await wait(character === " " ? 84 : 92);
      }

      typeCursor.classList.remove("is-typing");
      await wait(1500);
      typeCursor.classList.add("is-typing");

      for (let i = phrase.length - 1; i >= 0; i -= 1) {
        if (token !== loopToken) {
          return;
        }
        typeTarget.textContent = phrase.slice(0, i);
        await wait(38);
      }

      typeCursor.classList.remove("is-typing");
      await wait(340);
    }
  };

  typeTarget.textContent = "";
  primeAudioData();
  ["pointerdown", "keydown", "touchstart"].forEach((eventName) => {
    window.addEventListener(eventName, () => {
      unlockAudio().catch(() => {});
    }, { once: true, passive: true });
  });

  runTypeLoop(loopToken);
}

const revealObserver = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add("visible");
      }
    });
  },
  { threshold: 0.14 }
);

document.querySelectorAll(".reveal").forEach((node) => revealObserver.observe(node));
