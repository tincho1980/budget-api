module ApplicationHelper
  # Back-office sections: label and path. The active one is highlighted in the nav.
  def admin_nav_items
    [
      [ "Dashboard", admin_root_path ],
      [ "Clientes", admin_clients_path ],
      [ "Proyectos", admin_projects_path ],
      [ "Horas", admin_time_entries_path ],
      [ "Contratos", admin_maintenance_contracts_path ],
      [ "Cuotas", admin_maintenance_charges_path ],
      [ "Pagos", admin_payments_path ],
      [ "Tarifas", admin_rates_path ],
      [ "Usuarios", admin_users_path ]
    ]
  end

  # A section is active on its own path and on any path below it
  # (/admin/clients/3/edit keeps "Clientes" active). The dashboard only on its own.
  def admin_nav_link(label, path)
    active = path == admin_root_path ? (current_page?(path) || current_page?(root_path)) : request.path.start_with?(path)
    link_to label, path, class: [ "nav-link", ("nav-link-active" if active) ], aria: { current: ("page" if active) }
  end

  def initials(name)
    name.to_s.split.first(2).map { |word| word[0] }.join.upcase
  end
end
