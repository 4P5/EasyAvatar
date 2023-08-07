var deletables=[]
BBPlugin.register('easy_avatar', {
	title: 'Easy Avatar',
	author: '4P5',
	icon: 'icon',
	description: 'Create toggleable accessories, animations, and more without scripting!',
	version: '1.0.0',
	variant: 'both',
	onload() {
		/**
		 * @type {{[formElement: string]: "_" | DialogFormElement}}
		 */
		
		deletables.push(new Property(Cube, 'string', 'accessory_name'));
		deletables.push(new Property(Cube, 'string', 'accessory_item'));
		deletables.push(new Property(Group, 'string', 'accessory_name'));
		deletables.push(new Property(Group, 'string', 'accessory_item'));
		button=new Action('accessory', {
			name: 'Figura Accessory Properties',
			icon: 'extension',
			click: function () {
				const form = {
					name: { label: 'Name', type: 'string' },
					item: { label: 'Item', type: 'string' },
				}
				new Dialog({
					title: 'Accessory Properties',
					id: 'accessories',
					form,
					data: {
						name: this.accessory_name,
						item: this.accessory_item,
					},
					onConfirm: (data) => {
						if (data.name && data.item) {
							this.accessory_name = data.name
							this.accessory_item = data.item
						}
					},
				}).show()
			},
			condition: { modes: ['edit'], method: () => true },
		})
		deletables.push(button)
		Cube.prototype.menu.addAction(button);
		Group.prototype.menu.addAction(button);

		button = new Action('avatar_properties', {
			name: 'Avatar Properties',
			description: 'Figura-specific settings and config',
			icon: 'developer_mode',
			click() {
				const form = {
					hide_vanilla_player: { label: 'Hide Vanilla Player', type: 'checkbox', value: true },
					hide_vanilla_armor: { label: 'Hide Vanilla Armor', type: 'checkbox', value: false },
					author: { label: 'Author', type: 'string' },
					color: { label: 'Color', type: 'color' },

				}
				new Dialog({
					title: 'Avatar Properties',
					id: 'avatar_properties',
					form,
					data: {
						hide_vanilla: this.hide_vanilla,
						authors: this.authors,
					},
					onConfirm: (data) => {
						this.hide_vanilla = data.hide_vanilla
						this.authors = data.authors
					},
				}).show()
			}
		})
		MenuBar.addAction(button, 'file')
		deletables.push(button)
	},
	onunload(){
		deletables.forEach((deletable)=>deletable.delete())
	}
})