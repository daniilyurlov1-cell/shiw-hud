document.addEventListener('DOMContentLoaded', function() {
    var createApp = Vue.createApp;

    var app = createApp({
        data: function() {
            return {
                show: false,
                editMode: false,
                inventoryOpen: false,
                health: 100,
                stamina: 100,
                armor: 0,
                hunger: 100,
                thirst: 100,
                bladder: 0,
                cleanliness: 100,
                stress: 0,
                talking: false,
                temp: 0,
                tempValue: 20,
                onHorse: false,
                horsehealth: 0,
                horsestamina: 0,
                horseclean: 0,
                voice: 0,
                voiceAlwaysVisible: false,
                youhavemail: false,
                outlawstatus: 0,
                iconColors: {},
                locales: {},
                showLogo: false,
                logoImage: '',
                logoStyle: {}
            }
        },
        computed: {
            voiceProgress: function() {
                return 100;
            },
            showVoice: function() {
                return this.voiceAlwaysVisible || this.talking;
            },
            voiceColor: function() {
                return 'grey-6';
            },
            voiceIconColor: function() {
                return '#9e9e9e';
            },
            showHealth: function() {
                return this.health < 50 || this.editMode || this.inventoryOpen;
            },
            showStamina: function() {
                return this.stamina < 50 || this.editMode || this.inventoryOpen;
            },
            showHunger: function() {
                return this.hunger < 50 || this.editMode || this.inventoryOpen;
            },
            showThirst: function() {
                return this.thirst < 50 || this.editMode || this.inventoryOpen;
            },
            showBladder: function() {
                return this.bladder > 50 || this.editMode || this.inventoryOpen;
            },
            showCleanliness: function() {
                return this.cleanliness < 50 || this.editMode || this.inventoryOpen;
            },
            showStress: function() {
                return this.stress > 50 || this.editMode || this.inventoryOpen;
            },
            showYouHaveMail: function() {
                return this.youhavemail || this.editMode;
            },
            tempIcon: function() {
                if (this.tempValue > 40) {
                    return 'fas fa-sun';
                } else if (this.tempValue < 4) {
                    return 'fas fa-snowflake';
                }
                return 'fas fa-thermometer-half';
            },
            showTemp: function() {
                return this.tempValue < 4 || this.tempValue > 40 || this.editMode;
            },
            showTempColor: function() {
                if (this.tempValue > 40) return '#ff6b6b';
                if (this.tempValue < 4) return '#4fc3f7';
                return '#9e9e9e';
            },
            showoutlawstatus: function() {
                return this.outlawstatus > 0 || this.editMode;
            },
            showHorseHealth: function() {
                return (this.onHorse && this.horsehealth < 50) || this.editMode || (this.onHorse && this.inventoryOpen);
            },
            showHorseStamina: function() {
                return (this.onHorse && this.horsestamina < 50) || this.editMode || (this.onHorse && this.inventoryOpen);
            },
            showHorseClean: function() {
                return (this.onHorse && this.horseclean < 50) || this.editMode || (this.onHorse && this.inventoryOpen);
            },
            showHealthColor: function() {
                return this.health <= 30 ? '#ffffff' : '#9e9e9e';
            },
            showStaminaColor: function() {
                return this.stamina <= 30 ? '#ffffff' : '#9e9e9e';
            },
            showHungerColor: function() {
                return this.hunger <= 30 ? '#ffffff' : '#9e9e9e';
            },
            showThirstColor: function() {
                return this.thirst <= 30 ? '#ffffff' : '#9e9e9e';
            },
            showBladderColor: function() {
                if (this.bladder >= 90) return '#ffffff';
                if (this.bladder >= 70) return '#d0d0d0';
                return '#9e9e9e';
            },
            showCleanlinessColor: function() {
                return '#9e9e9e';
            },
            showStressColor: function() {
                if (this.stress >= 80) return '#ffffff';
                if (this.stress >= 70) return '#d0d0d0';
                return '#9e9e9e';
            },
            showYouHaveMailColor: function() {
                return this.youhavemail ? '#ffffff' : '#9e9e9e';
            },
            showOutLawColor: function() {
                return this.outlawstatus > 0 ? '#ffffff' : '#9e9e9e';
            },
            showHorseHealthColor: function() {
                return this.horsehealth <= 30 ? '#ffffff' : '#9e9e9e';
            },
            showHorseStaminaColor: function() {
                return this.horsestamina <= 30 ? '#ffffff' : '#9e9e9e';
            },
            showHorseCleanColor: function() {
                return this.horseclean <= 30 ? '#ffffff' : '#9e9e9e';
            }
        },        
        methods: {
            // Вспомогательная функция для безопасного получения числовых значений
            getNumericValue: function(value, defaultValue) {
                if (value === undefined || value === null) {
                    return defaultValue;
                }
                var num = Number(value);
                return isNaN(num) ? defaultValue : num;
            },

            handleNUIMessage: function(event) {
                var self = this;
                var data = event.data;
                
                if (data.action === 'hudtick') {
                    // Булевые значения - используем !! для корректного преобразования
                    this.show = !!data.show;
                    this.inventoryOpen = !!data.inventoryOpen;
                    this.talking = !!data.talking;
                    this.onHorse = !!data.onHorse;
                    this.voiceAlwaysVisible = !!data.voiceAlwaysVisible;
                    this.youhavemail = !!data.youhavemail;
                    
                    // Числовые значения игрока - ИСПРАВЛЕНО: корректная обработка 0
                    this.health = self.getNumericValue(data.health, 100);
                    this.stamina = self.getNumericValue(data.stamina, 100);
                    this.armor = self.getNumericValue(data.armor, 0);
                    this.hunger = self.getNumericValue(data.hunger, 100);
                    this.thirst = self.getNumericValue(data.thirst, 100);
                    this.bladder = self.getNumericValue(data.bladder, 0);
                    this.cleanliness = self.getNumericValue(data.cleanliness, 100);
                    this.stress = self.getNumericValue(data.stress, 0);
                    this.outlawstatus = self.getNumericValue(data.outlawstatus, 0);
                    this.voice = self.getNumericValue(data.voice, 0);
                    
                    // Температура
                    this.temp = self.getNumericValue(data.temp, 0);
                    if (data.tempValue !== undefined) {
                        this.tempValue = self.getNumericValue(data.tempValue, 20);
                    } else if (typeof data.temp === 'string') {
                        var match = data.temp.match(/-?\d+/);
                        if (match) {
                            this.tempValue = parseInt(match[0]);
                        }
                    }
                    
                    // Числовые значения лошади - ИСПРАВЛЕНО: корректная обработка 0
                    this.horsehealth = self.getNumericValue(data.horsehealth, 0);
                    this.horsestamina = self.getNumericValue(data.horsestamina, 0);
                    this.horseclean = self.getNumericValue(data.horseclean, 0);
                    
                    // Объекты
                    if (data.iconColors && typeof data.iconColors === 'object') {
                        this.iconColors = data.iconColors;
                    }
                    
                    // Конфигурация логотипа
                    if (data.logoConfig) {
                        this.showLogo = !!data.logoConfig.show;
                        this.logoImage = data.logoConfig.image || '';
                        if (data.logoConfig.show && data.logoConfig.image) {
                            this.logoStyle = {
                                width: (data.logoConfig.size || 150) + 'px',
                                opacity: data.logoConfig.opacity || 0.8,
                                position: 'fixed',
                                top: data.logoConfig.position ? data.logoConfig.position.top : '20px',
                                right: data.logoConfig.position ? data.logoConfig.position.right : '20px'
                            };
                        }
                    }
                }
                
                if (data.action === 'inventoryOpen') {
                    this.inventoryOpen = true;
                    this.show = true;
                    console.log('[HUD] Inventory opened - showing status icons');
                }
                
                if (data.action === 'inventoryClose') {
                    this.inventoryOpen = false;
                    console.log('[HUD] Inventory closed - normal icon visibility');
                }
                
                if (data.action === 'toggleEditMode') {
                    this.editMode = !!data.enabled;
                    this.setupDraggableElements();
                }
                
                if (data.action === 'resetPositions') {
                    this.resetPositions();
                }
                
                if (data.action === 'setLocales') {
                    if (data.locales && typeof data.locales === 'object') {
                        this.locales = data.locales;
                    }
                }
            },

            setupDraggableElements: function() {
                var self = this;
                var container = document.getElementById('main-container');
                if (!container) return;

                var draggableElements = container.querySelectorAll('.draggable-element');
                
                draggableElements.forEach(function(element) {
                    if (self.editMode) {
                        element.classList.add('edit-mode');
                        self.makeDraggable(element);
                    } else {
                        element.classList.remove('edit-mode');
                        self.removeDraggable(element);
                    }
                });
            },

            makeDraggable: function(element) {
                var self = this;
                var isDragging = false;
                var startX, startY, initialLeft, initialTop;

                var onMouseDown = function(e) {
                    if (!self.editMode) return;
                    if (e.target.classList.contains('resize-handle')) return;

                    isDragging = true;
                    element.classList.add('dragging');
                    
                    startX = e.clientX;
                    startY = e.clientY;
                    
                    var rect = element.getBoundingClientRect();
                    initialLeft = rect.left;
                    initialTop = rect.top;
                    
                    element.style.position = 'fixed';
                    element.style.left = initialLeft + 'px';
                    element.style.top = initialTop + 'px';
                    element.style.zIndex = '9999';
                    
                    e.preventDefault();
                };

                var onMouseMove = function(e) {
                    if (!isDragging || !self.editMode) return;
                    
                    var deltaX = e.clientX - startX;
                    var deltaY = e.clientY - startY;
                    
                    element.style.left = (initialLeft + deltaX) + 'px';
                    element.style.top = (initialTop + deltaY) + 'px';
                };

                var onMouseUp = function(e) {
                    if (!isDragging) return;
                    
                    isDragging = false;
                    element.classList.remove('dragging');
                    
                    var elementName = element.getAttribute('data-element');
                    var rect = element.getBoundingClientRect();
                    
                    self.savePosition(elementName, {
                        left: rect.left,
                        top: rect.top
                    });
                };

                element._dragHandlers = { onMouseDown: onMouseDown, onMouseMove: onMouseMove, onMouseUp: onMouseUp };
                
                element.addEventListener('mousedown', onMouseDown);
                document.addEventListener('mousemove', onMouseMove);
                document.addEventListener('mouseup', onMouseUp);
            },

            removeDraggable: function(element) {
                if (element._dragHandlers) {
                    element.removeEventListener('mousedown', element._dragHandlers.onMouseDown);
                    document.removeEventListener('mousemove', element._dragHandlers.onMouseMove);
                    document.removeEventListener('mouseup', element._dragHandlers.onMouseUp);
                    delete element._dragHandlers;
                }
                
                element.style.position = '';
                element.style.left = '';
                element.style.top = '';
                element.style.zIndex = '';
            },

            savePosition: function(elementName, position) {
                var savedPositions = JSON.parse(localStorage.getItem('hudPositions')) || {};
                savedPositions[elementName] = position;
                localStorage.setItem('hudPositions', JSON.stringify(savedPositions));
            },

            loadPositions: function() {
                var self = this;
                var savedPositions = JSON.parse(localStorage.getItem('hudPositions')) || {};
                
                Object.keys(savedPositions).forEach(function(elementName) {
                    var element = document.querySelector('[data-element="' + elementName + '"]');
                    if (element) {
                        var position = savedPositions[elementName];
                        element.style.position = 'fixed';
                        element.style.left = position.left + 'px';
                        element.style.top = position.top + 'px';
                    }
                });
            },

            resetPositions: function() {
                localStorage.removeItem('hudPositions');
                
                var draggableElements = document.querySelectorAll('.draggable-element');
                draggableElements.forEach(function(element) {
                    element.style.position = '';
                    element.style.left = '';
                    element.style.top = '';
                });
            },

            handleKeyPress: function(e) {
                var self = this;
                if (e.key === 'Escape' && self.editMode) {
                    fetch('https://' + GetParentResourceName() + '/disableEditMode', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({})
                    });
                    self.editMode = false;
                    self.setupDraggableElements();
                }
            }
        },

        mounted: function() {
            var self = this;
            window.addEventListener('message', this.handleNUIMessage);
            window.addEventListener('keydown', this.handleKeyPress);
            
            setTimeout(function() {
                self.loadPositions();
            }, 500);
        },

        unmounted: function() {
            window.removeEventListener('message', this.handleNUIMessage);
            window.removeEventListener('keydown', this.handleKeyPress);
        }
    });

    app.use(Quasar);
    app.mount('#main-container');
});