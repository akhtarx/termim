document.addEventListener('DOMContentLoaded', () => {

    // 1. Mouse Tracking Glow Effect for Bento Cards & Ambient Background
    window.addEventListener("mousemove", e => {
        const x = e.clientX;
        const y = e.clientY;
        
        // Global background spotlight
        document.documentElement.style.setProperty('--bg-mouse-x', `${x}px`);
        document.documentElement.style.setProperty('--bg-mouse-y', `${y}px`);
    });
    
    document.querySelectorAll('.glow-card').forEach(card => {
        card.addEventListener('mousemove', e => {
            const rect = card.getBoundingClientRect();
            const x = e.clientX - rect.left;
            const y = e.clientY - rect.top;
            card.style.setProperty('--mouse-x', `${x}px`);
            card.style.setProperty('--mouse-y', `${y}px`);
        });
    });

    // 2. Scroll Reveal (Intersection Observer)
    const observerOptions = {
        root: null,
        rootMargin: '0px',
        threshold: 0.15
    };

    const observer = new IntersectionObserver((entries, obs) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible');
                obs.unobserve(entry.target);
            }
        });
    }, observerOptions);

    document.querySelectorAll('.reveal').forEach(el => observer.observe(el));

    // 3. Tab Management for Installation
    const osBtns = document.querySelectorAll('.os-btn');
    const codeBoxes = document.querySelectorAll('.code-box');

    osBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            osBtns.forEach(b => b.classList.remove('active'));
            codeBoxes.forEach(c => c.classList.remove('active'));
            
            btn.classList.add('active');
            const targetId = `code-${btn.getAttribute('data-os')}`;
            document.getElementById(targetId).classList.add('active');
        });
    });

    // 4. Hero Terminal Simulation Overhaul (The Ultimate Professional)
    const termBody = document.getElementById('hero-term');
    const narrativeBadge = document.getElementById('term-narrative');
    
    // Create Key Hint Toast
    const keyHint = document.createElement('div');
    keyHint.className = 'key-hint';
    termBody.appendChild(keyHint);

    async function updateNarrative(text) {
        narrativeBadge.classList.remove('visible');
        await new Promise(r => setTimeout(r, 400));
        narrativeBadge.textContent = text;
        narrativeBadge.classList.add('visible');
    }

    async function pressKey(keyName, holdTime = 800) {
        keyHint.textContent = keyName;
        keyHint.classList.add('show');
        
        await new Promise(r => setTimeout(r, holdTime)); // Pause to read key
        
        keyHint.classList.add('press');
        
        // Return a promise that resolves when the "CLICK" happens, 
        // but continue the 2s visibility in the background
        return new Promise(r => {
            setTimeout(() => {
                keyHint.classList.remove('press');
                r(); // PROCEED with terminal logic immediately after click
                
                // Background fade out
                setTimeout(() => {
                    keyHint.classList.remove('show');
                }, 2000);
            }, 120);
        });
    }

    async function typeWithHints(element, text) {
        keyHint.textContent = 'TYPING...';
        keyHint.classList.add('show', 'is-typing');
        
        for (let char of text) {
            element.textContent += char;
            const jitter = (Math.random() * 30) - 15;
            await new Promise(r => setTimeout(r, 65 + jitter));
        }
        
        keyHint.classList.remove('is-typing');
        // Hide in background after 2s
        setTimeout(() => {
            keyHint.classList.remove('show');
        }, 2000);
        
        await new Promise(r => setTimeout(r, 100)); // Minor bridge to next action
    }

    const terminalScenario = [
        // SCENE 1: Web Frontend Context
        { action: 'narrative', content: `Scenario: Working in React App`, delay: 1000 },
        { action: 'type', content: `cd ~/projects/react-webapp`, delay: 1200 },
        { action: 'key', content: `ENTER`, delay: 200 },
        
        { action: 'type', content: `npm run dev`, delay: 2000 },
        { action: 'key', content: `ENTER`, delay: 200 },
        { action: 'output', content: `\n> next dev\n- ready on http://localhost:3000\n`, delay: 2000 },

        // SCENE 2: The Critical Context Switch
        { action: 'narrative', content: `Switching to Django Backend API`, delay: 3500 },
        { action: 'type', content: `cd ../django-api`, delay: 2000 },
        { action: 'key', content: `ENTER`, delay: 200 },

        { action: 'narrative', content: `Proof: Project History Isolation`, delay: 2000 },
        { action: 'key', content: `UP ARROW`, delay: 2500 },
        { action: 'instant', content: `<span class="t-success">python manage.py runserver</span>`, delay: 200 },
        { action: 'instruction', content: `Result: Isolated history. Commands from 'react-webapp' are invisible here.`, delay: 4500 },
        { action: 'key', content: `ENTER`, delay: 200 },
        { action: 'output', content: `\nQuit server with CTRL-BREAK.\nStarting development server at http://127.0.0.1:8000/\n`, delay: 2000 },

        // SCENE 3: Intelligent Prediction
        { action: 'narrative', content: `Intelligence: Behavioral Prediction`, delay: 3500 },
        { action: 'type', content: `git status`, delay: 2000 },
        { action: 'key', content: `ENTER`, delay: 200 },
        { action: 'output', content: `\nOn branch main\nChanges not staged for commit:\n  modified:   schema.sql\n`, delay: 1500 },
        
        { action: 'key', content: `DOWN ARROW`, delay: 1500 }, // Predicting next MOVE (Forward in time)
        { action: 'instant', content: `<span class="t-prediction">git add . && git commit -m "update schema"</span>`, delay: 200 },
        { action: 'instruction', content: `Termim: Suggested next command via Markov-chain analysis.`, delay: 3000 },
        { action: 'key', content: `ENTER`, delay: 200 },
        { action: 'output', content: `\n[main 8a4c12] update schema\n 1 file changed, 12 insertions(+)\n`, delay: 1500 },

        // SCENE 4: Global Access
        { action: 'narrative', content: `Mastery: Global Fallback Access`, delay: 3500 },
        { action: 'key', content: `UP ARROW`, delay: 1500 },
        { action: 'instant', content: `<span class="t-success">git commit -m "update schema"</span>`, delay: 200 },
        { action: 'key', content: `UP ARROW`, delay: 1500 },
        { action: 'instant', content: `<span class="t-success">git status</span>`, delay: 200 },
        
        { action: 'instruction', content: `Local history exhausted. Searching global fallback...`, delay: 3500 },
        { action: 'key', content: `UP ARROW`, delay: 2000 },
        { action: 'instant', content: `<span class="t-arg">ssh admin@audit-logs.cloud</span> <span class="t-comment"># Global shell history fallback</span>`, delay: 200 },
        { action: 'key', content: `ENTER`, delay: 200 }
    ];

    // Viewport-aware execution control
    let isTermVisible = false;
    const termObserver = new IntersectionObserver((entries) => {
        isTermVisible = entries[0].isIntersecting;
    }, { threshold: 0.1 });
    termObserver.observe(termBody);

    async function waitIfHidden() {
        if (isTermVisible) return;
        return new Promise(resolve => {
            const interval = setInterval(() => {
                if (isTermVisible) {
                    clearInterval(interval);
                    resolve();
                }
            }, 100);
        });
    }

    async function typeTerminal() {
        termBody.innerHTML = '';
        termBody.appendChild(keyHint);
        updateNarrative("Termim Engine: Active");
        
        for (let step of terminalScenario) {
            await waitIfHidden(); // PAUSE IF NOT IN VIEW
            await new Promise(r => setTimeout(r, step.delay));
            await waitIfHidden(); // Double check after delay
            
            if (step.action === 'narrative') {
                await updateNarrative(step.content);

            } else if (step.action === 'instruction') {
                const instr = document.createElement('div');
                instr.className = 't-instruction success';
                instr.textContent = `# ${step.content}`;
                termBody.appendChild(instr);

            } else if (step.action === 'type') {
                const line = document.createElement('div');
                line.className = 'term-line';
                line.innerHTML = `<span class="prompt">$</span><span class="typing"></span>`;
                termBody.appendChild(line);
                
                const typingSpan = line.querySelector('.typing');
                await typeWithHints(typingSpan, step.content);

            } else if (step.action === 'key') {
                await pressKey(step.content);

            } else if (step.action === 'instant') {
                const line = document.createElement('div');
                line.className = 'term-line';
                line.innerHTML = `<span class="prompt">$</span>${step.content}`;
                termBody.appendChild(line);
                line.style.opacity = '0';
                line.style.transition = 'opacity 0.2s';
                setTimeout(() => line.style.opacity = '1', 50);

            } else if (step.action === 'output') {
                const outWrapper = document.createElement('div');
                outWrapper.className = 't-comment';
                outWrapper.style.whiteSpace = 'pre';
                outWrapper.textContent = step.content;
                termBody.appendChild(outWrapper);
            }
            
            termBody.scrollTop = termBody.scrollHeight;
        }

        // Loop pause
        await new Promise(r => setTimeout(r, 6000));
        typeTerminal();
    }
    
    const style = document.createElement('style');
    style.innerHTML = `@keyframes blink { 0%, 100% { opacity: 1; } 50% { opacity: 0; } }`;
    document.head.appendChild(style);
    
    setTimeout(typeTerminal, 1000);

    // 5. FAQ Accordion Logic
    const faqTriggers = document.querySelectorAll('.faq-trigger');
    faqTriggers.forEach(trigger => {
        trigger.addEventListener('click', () => {
            const item = trigger.closest('.faq-item');
            
            // Close others
            document.querySelectorAll('.faq-item').forEach(otherItem => {
                if(otherItem !== item) {
                    otherItem.classList.remove('active');
                }
            });

            // Toggle current
            item.classList.toggle('active');
        });
    });

    // 7. Dynamic GitHub Stars
    async function fetchGitHubStars() {
        try {
            const response = await fetch('https://api.github.com/repos/akhtarx/termim');
            const data = await response.json();
            const stars = data.stargazers_count;
            if (stars !== undefined) {
                document.querySelectorAll('.star-count').forEach(el => {
                    el.textContent = stars.toLocaleString();
                });
            }
        } catch (error) {
            console.error('Failed to fetch stars', error);
        }
    }
    fetchGitHubStars();

    // Synchronized Comparison Storyboard Logic
    const storyScenes = document.querySelectorAll('.story-scene');
    const scenDots = document.querySelectorAll('.scen-dot');
    const scenPrev = document.getElementById('scen-prev');
    const scenNext = document.getElementById('scen-next');
    const scenTitle = document.getElementById('scen-title');
    const scenDesc = document.getElementById('scen-desc');
    
    let currentScene = 0;
    const totalScenes = 4;

    const scenarioMeta = [
        { title: "Project Isolation", desc: "Termim understands project boundaries. Your history stays where it belongs." },
        { title: "Behavioral Prediction", desc: "Markov-chain analysis predicts your next command before you even type it." },
        { title: "The Privacy Sieve", desc: "Automatic redaction scrubs credentials and secrets before they hit your disk." },
        { title: "Success-Only History", desc: "Zero noise. Termim prunes typos and failed commands for a cleaner workflow." }
    ];

    function updateStoryboard(index) {
        // Clamp index
        if (index < 0) index = totalScenes - 1;
        if (index >= totalScenes) index = 0;
        currentScene = index;

        // Update Metadata
        if (scenTitle && scenDesc) {
            scenTitle.style.opacity = '0';
            scenDesc.style.opacity = '0';
            
            setTimeout(() => {
                scenTitle.textContent = scenarioMeta[currentScene].title;
                scenDesc.textContent = scenarioMeta[currentScene].desc;
                scenTitle.style.opacity = '1';
                scenDesc.style.opacity = '1';
            }, 300);
        }

        // Update all scenes in both cards
        document.querySelectorAll('.story-scene').forEach(scene => {
            scene.classList.remove('active');
            if (parseInt(scene.dataset.scene) === currentScene) {
                scene.classList.add('active');
            }
        });

        // Update dots
        scenDots.forEach((dot, idx) => {
            dot.classList.toggle('active', idx === currentScene);
        });
    }

    scenPrev?.addEventListener('click', () => updateStoryboard(currentScene - 1));
    scenNext?.addEventListener('click', () => updateStoryboard(currentScene + 1));
    scenDots.forEach(dot => {
        dot.addEventListener('click', () => updateStoryboard(parseInt(dot.dataset.index)));
    });

    // Add CSS transition for titles
    if(scenTitle) {
        scenTitle.style.transition = 'opacity 0.3s ease';
        scenDesc.style.transition = 'opacity 0.3s ease';
    }

});

// 6. Copy to Clipboard Utility
function copyToClipboard(btn) {
    const code = btn.previousElementSibling.innerText;
    navigator.clipboard.writeText(code).then(() => {
        const originalText = btn.innerText;
        btn.innerText = 'Copied!';
        btn.style.background = '#27c93f';
        btn.style.color = '#fff';
        setTimeout(() => {
            btn.innerText = originalText;
            btn.style.background = '#fff';
            btn.style.color = '#000';
        }, 2000);
    });
}
